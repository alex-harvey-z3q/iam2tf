#!/bin/bash

script_under_test="iam2tf.sh"

oneTimeSetUp() {
  # shellcheck disable=SC1090
  . "$script_under_test"
}

test_camelCase_conversion() {
  result="$(_sanitize <<< "camelCase")"
  assertEquals "camel_case" "$result"
}

test_PascalCase_conversion() {
  result="$(_sanitize <<< "PascalCase")"
  assertEquals "pascal_case" "$result"
}

test_multipleCamelCase() {
  result="$(_sanitize <<< "thisIsALongCamelCaseString")"
  assertEquals "this_is_a_long_camel_case_string" "$result"
}

test_consecutiveUppercase() {
  result="$(_sanitize <<< "XMLParser")"
  assertEquals "xml_parser" "$result"
}

test_acronymInCamelCase() {
  result="$(_sanitize <<< "parseHTMLContent")"
  assertEquals "parse_html_content" "$result"
}

test_uppercase_to_lowercase() {
  result="$(_sanitize <<< "UPPERCASE")"
  assertEquals "uppercase" "$result"
}

test_mixedCase_to_lowercase() {
  result="$(_sanitize <<< "MiXeD cAsE")"
  assertEquals "mi_xe_d_c_as_e" "$result"
}

test_spaces_replaced() {
  result="$(_sanitize <<< "hello world")"
  assertEquals "hello_world" "$result"
}

test_hyphens_replaced() {
  result="$(_sanitize <<< "hello-world-test")"
  assertEquals "hello_world_test" "$result"
}

test_dots_replaced() {
  result="$(_sanitize <<< "file.name.txt")"
  assertEquals "file_name_txt" "$result"
}

test_multiple_special_chars() {
  result="$(_sanitize <<< "hello@#$%world!")"
  assertEquals "hello_world" "$result"
}

test_consecutive_special_chars() {
  result="$(_sanitize <<< "hello---world")"
  assertEquals "hello_world" "$result"
}

test_numbers_preserved() {
  result="$(_sanitize <<< "test123")"
  assertEquals "test123" "$result"
}

test_numbers_with_camelCase() {
  result="$(_sanitize <<< "test123CamelCase")"
  assertEquals "test123_camel_case" "$result"
}

test_numbers_with_special_chars() {
  result="$(_sanitize <<< "test-123-file")"
  assertEquals "test_123_file" "$result"
}

test_empty_string() {
  result="$(_sanitize <<< "")"
  assertEquals "" "$result"
}

test_single_character() {
  result="$(_sanitize <<< "a")"
  assertEquals "a" "$result"
}

test_single_uppercase() {
  result="$(_sanitize <<< "A")"
  assertEquals "a" "$result"
}

test_only_special_chars() {
  result="$(_sanitize <<< "@#_$%^&_*()")"
  assertEquals "" "$result"
}

test_only_underscores() {
  result="$(_sanitize <<< "___")"
  assertEquals "" "$result"
}

test_leading_uppercase() {
  result="$(_sanitize <<< "UpperCase")"
  assertEquals "upper_case" "$result"
}

test_trailing_special_chars() {
  result="$(_sanitize <<< "test!!!")"
  assertEquals "test" "$result"
}

test_leading_special_chars() {
  result="$(_sanitize <<< "!!!test")"
  assertEquals "test" "$result"
}

# shellcheck disable=SC1091
. shunit2
