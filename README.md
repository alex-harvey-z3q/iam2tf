# AWS IAM to Terraform Converter

A script that automatically converts your existing AWS IAM roles and policies into Terraform HCL code, making it easy to import manually-created IAM roles.

## Overview

This script reads through all IAM roles and policies in your AWS account and generates corresponding Terraform resources, including:
- IAM roles with assume role policies
- Inline role policies
- Policy attachments to roles
- Standalone IAM policies (locally scoped)

## Prerequisites

Requires:
- AWS CLI
- jq
- [iam-policy-json-to-terraform](https://github.com/flosell/iam-policy-json-to-terraform)

## Usage

```bash
bash iam2tf.sh > iam.tf
```

To add a prefix and specify a separator:

```bash
bash iam2tf.sh -n SomePrefix -s"-" > iam.tf
```

## Output

The script generates Terraform HCL code to stdout.

## Features

### Scope Filtering
- Only processes roles in the root path (`/`)
- Only processes locally scoped policies (excludes AWS managed policies)

## Limitations

- Only processes roles and policies in the root path (`/`)
- Does not handle AWS managed policies (only locally scoped policies)
- Does not generate Terraform import statements (you'll need to import existing resources manually if needed)

## License

MIT.
