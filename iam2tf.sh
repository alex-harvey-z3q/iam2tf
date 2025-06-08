#!/usr/bin/env bash

export AWS_DEFAULT_REGION="ap-southeast-2"

usage() {
  echo "Usage: bash $0 [-h]"
  echo "A script that reads through all IAM roles and generates HCL Terraform code"
  exit 1
}

preflight_checks() {
  local dependencies=(aws jq iam-policy-json-to-terraform)
  for cmd in "${dependencies[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Error: Required command '$cmd' is not installed." >&2
      exit 1
    fi
  done
}

_sanitise() {
  # Converts AWS resource names (which may use camelCase or contain special characters)
  # into valid Terraform resource identifiers that follow snake_case naming conventions.
  #
  awk '
  {
    # Insert _ before uppercase letters (for camelCase)
    for (i = length($0); i > 1; i--) {
      if (substr($0, i, 1) ~ /[A-Z]/) {

        # But also handle strings like "XMLParser" differently
        prev_is_upper = (i > 1 && substr($0, i-1, 1) ~ /[A-Z]/)

        # Check if next char is lowercase
        next_is_lower = (i < length($0) && substr($0, i+1, 1) ~ /[a-z]/)

        # Insert underscore if:
        # 1. Previous char is not uppercase (start of word)
        # 2. OR previous char is uppercase AND next char is lowercase (end of acronym)
        if (!prev_is_upper || (prev_is_upper && next_is_lower)) {
          $0 = substr($0, 1, i-1) "_" substr($0, i)
        }
      }
    }

    # Convert to lowercase
    $0 = tolower($0)

    # Replace non-alphanumerics with _
    gsub(/[^a-z0-9]+/, "_")

    # Remove leading and trailing underscores
    gsub(/^_+|_+$/, "")

    print
  }
  '
}

##
## AWS CLI Wrappers
##

_list_roles() { aws iam list-roles; }

_get_role_by_role_name() { aws iam get-role --role-name "$1"; }

_list_role_policies_by_role_name() { aws iam list-role-policies --role-name "$1"; }

_get_role_policy_by_role_name_and_policy_name() { aws iam get-role-policy --role-name "$1" --policy-name "$2"; }

_list_attached_role_policies_by_role_name() { aws iam list-attached-role-policies --role-name "$1"; }

_list_policies() { aws iam list-policies --scope Local; }

_get_policy_by_policy_arn() { aws iam get-policy --policy-arn "$1"; }

_get_policy_version_by_policy_arn_and_version_id() { aws iam get-policy-version --policy-arn "$1" --version-id "$2"; }

##
## Text filters
##

_space() { cat; echo; }  # Add one blank line at the end of STDIN.

_filter_role_names() { jq -r '.Roles[] | select(.Path == "/") | .RoleName'; }

_filter_policy_arns() { jq -r '.Policies[] | select(.Path == "/") | .Arn'; }

_filter_default_version_id() { jq -r '.Policy.DefaultVersionId'; }

_filter_policy_version_document() { jq -r '.PolicyVersion.Document'; }

_filter_assume_role_policy_document() { jq -r '.Role.AssumeRolePolicyDocument'; }

_filter_policy_names() { jq -r '.PolicyNames[]'; }

_filter_policy_document() { jq -r '.PolicyDocument'; }

_filter_attached_policy_arns() { jq -r '.AttachedPolicies[].PolicyArn'; }

_filter_policy_name() { grep -o '[^/]*$'; }

##
## HCL generation functions
##

_policy_to_hcl() { iam-policy-json-to-terraform -name "$1"; }

_generate_role_hcl() {
  local role_name="$1"
  local sanitised_role_name="$2"

  _get_role_by_role_name "$role_name" | _filter_assume_role_policy_document | _policy_to_hcl "$sanitised_role_name" | _space

  _space <<-EOF
		resource "aws_iam_role" "$sanitised_role_name" {
		  name               = "$role_name"
		  assume_role_policy = data.aws_iam_policy_document.$sanitised_role_name.json
		}
	EOF
}

_generate_role_policy_hcl() {
  local role_name="$1"
  local sanitised_role_name="$2"
  local policy_name="$3"

  local sanitised_policy_name
  sanitised_policy_name="$sanitised_role_name"__"$(_sanitise <<< "$policy_name")"

  _get_role_policy_by_role_name_and_policy_name "$role_name" "$policy_name" | _filter_policy_document | _policy_to_hcl "$sanitised_policy_name" | _space

  _space <<-EOF
		resource "aws_iam_role_policy" "$sanitised_policy_name" {
		  name   = "$policy_name"
		  policy = data.aws_iam_policy_document.$sanitised_policy_name.json
		  role   = aws_iam_role.$sanitised_role_name.id
		}
	EOF
}

_generate_role_policy_attachment_hcl() {
  local policy_arn="$1"
  local sanitised_role_name="$2"

  local policy_name
  policy_name="$(_filter_policy_name <<< "$policy_arn")"

  local sanitised_policy_attachment_name
  sanitised_policy_attachment_name="$sanitised_role_name"__"$(_sanitise <<< "$policy_name")"__attachment

  _space <<-EOF
		resource "aws_iam_role_policy_attachment" "$sanitised_policy_attachment_name" {
		  role       = aws_iam_role.$sanitised_role_name.name
		  policy_arn = "$policy_arn"
		}
	EOF
}

_generate_policy_hcl() {
  local policy_arn="$1"

  local policy_name
  policy_name="$(_filter_policy_name <<< "$policy_arn")"

  local sanitised_policy_name
  sanitised_policy_name="$(_sanitise <<< "$policy_name")"

  local version_id
  version_id="$(_get_policy_by_policy_arn "$policy_arn" | _filter_default_version_id)"

  _get_policy_version_by_policy_arn_and_version_id "$policy_arn" "$version_id" | _filter_policy_version_document | _policy_to_hcl "$sanitised_policy_name" | _space

  _space <<-EOF
		resource "aws_iam_policy" "$sanitised_policy_name" {
		  name   = "$policy_name"
		  policy = data.aws_iam_policy_document.$sanitised_policy_name.json
		}
	EOF
}

_generate_role_policies() {
  local role_name="$1"
  local sanitised_role_name="$2"
  local policy_name
  while read -r policy_name; do
    _generate_role_policy_hcl "$role_name" "$sanitised_role_name" "$policy_name"
  done < <(_list_role_policies_by_role_name "$role_name" | _filter_policy_names)
}

_generate_role_policy_attachments() {
  local role_name="$1"
  local sanitised_role_name="$2"
  local policy_arn
  while read -r policy_arn; do
    _generate_role_policy_attachment_hcl "$policy_arn" "$sanitised_role_name"
  done < <(_list_attached_role_policies_by_role_name "$role_name" | _filter_attached_policy_arns)
}

generate_roles() {
  local role_name
  local sanitised_role_name

  while read -r role_name; do
    sanitised_role_name="$(_sanitise <<< "$role_name")"
    _generate_role_hcl      "$role_name" "$sanitised_role_name"
    _generate_role_policies "$role_name" "$sanitised_role_name"
    _generate_role_policy_attachments "$role_name" "$sanitised_role_name"
  done < <(_list_roles | _filter_role_names)
}

generate_policies() {
  local policy_arn
  while read -r policy_arn; do
    _generate_policy_hcl "$policy_arn"
  done < <(_list_policies | _filter_policy_arns)
}

main() {
  if [[ "$1" = "-h" ]]; then
    usage
  fi

  preflight_checks

  generate_roles
  generate_policies
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  main "$@"
fi
