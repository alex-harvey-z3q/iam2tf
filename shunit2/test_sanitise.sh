#!/bin/bash

script_under_test="iam2tf.sh"

oneTimeSetUp() {
  # shellcheck disable=SC1090
  . "$script_under_test"
}

test_camelCase_conversion() {
  result="$(_sanitise <<< "camelCase")"
  assertEquals "camel_case" "$result"
}

test_PascalCase_conversion() {
  result="$(_sanitise <<< "PascalCase")"
  assertEquals "pascal_case" "$result"
}

test_multipleCamelCase() {
  result="$(_sanitise <<< "thisIsALongCamelCaseString")"
  assertEquals "this_is_a_long_camel_case_string" "$result"
}

test_consecutiveUppercase() {
  result="$(_sanitise <<< "XMLParser")"
  assertEquals "xml_parser" "$result"
}

test_acronymInCamelCase() {
  result="$(_sanitise <<< "parseHTMLContent")"
  assertEquals "parse_html_content" "$result"
}

test_uppercase_to_lowercase() {
  result="$(_sanitise <<< "UPPERCASE")"
  assertEquals "uppercase" "$result"
}

test_mixedCase_to_lowercase() {
  result="$(_sanitise <<< "MiXeD cAsE")"
  assertEquals "mi_xe_d_c_as_e" "$result"
}

test_spaces_replaced() {
  result="$(_sanitise <<< "hello world")"
  assertEquals "hello_world" "$result"
}

test_hyphens_replaced() {
  result="$(_sanitise <<< "hello-world-test")"
  assertEquals "hello_world_test" "$result"
}

test_dots_replaced() {
  result="$(_sanitise <<< "file.name.txt")"
  assertEquals "file_name_txt" "$result"
}

test_multiple_special_chars() {
  result="$(_sanitise <<< "hello@#$%world!")"
  assertEquals "hello_world" "$result"
}

test_consecutive_special_chars() {
  result="$(_sanitise <<< "hello---world")"
  assertEquals "hello_world" "$result"
}

test_numbers_preserved() {
  result="$(_sanitise <<< "test123")"
  assertEquals "test123" "$result"
}

test_numbers_with_camelCase() {
  result="$(_sanitise <<< "test123CamelCase")"
  assertEquals "test123_camel_case" "$result"
}

test_numbers_with_special_chars() {
  result="$(_sanitise <<< "test-123-file")"
  assertEquals "test_123_file" "$result"
}

test_empty_string() {
  result="$(_sanitise <<< "")"
  assertEquals "" "$result"
}

test_single_character() {
  result="$(_sanitise <<< "a")"
  assertEquals "a" "$result"
}

test_single_uppercase() {
  result="$(_sanitise <<< "A")"
  assertEquals "a" "$result"
}

test_only_special_chars() {
  result="$(_sanitise <<< "@#_$%^&_*()")"
  assertEquals "" "$result"
}

test_only_underscores() {
  result="$(_sanitise <<< "___")"
  assertEquals "" "$result"
}

test_leading_uppercase() {
  result="$(_sanitise <<< "UpperCase")"
  assertEquals "upper_case" "$result"
}

test_trailing_special_chars() {
  result="$(_sanitise <<< "test!!!")"
  assertEquals "test" "$result"
}

test_leading_special_chars() {
  result="$(_sanitise <<< "!!!test")"
  assertEquals "test" "$result"
}

# shellcheck disable=SC1091
. shunit2
