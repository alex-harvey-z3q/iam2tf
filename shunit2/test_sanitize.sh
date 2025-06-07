#!/bin/bash

script_under_test="iam2tf.sh"

oneTimeSetUp() {
  # shellcheck disable=SC1090
  . "$script_under_test"
}

test_camelCase_conversion() {
  result="$(echo "camelCase" | _sanitize)"
  assertEquals "camel_case" "$result"
}

test_PascalCase_conversion() {
  result="$(echo "PascalCase" | _sanitize)"
  assertEquals "pascal_case" "$result"
}

test_multipleCamelCase() {
  result="$(echo "thisIsALongCamelCaseString" | _sanitize)"
  assertEquals "this_is_a_long_camel_case_string" "$result"
}

test_consecutiveUppercase() {
  result="$(echo "XMLParser" | _sanitize)"
  assertEquals "xml_parser" "$result"
}

test_acronymInCamelCase() {
  result="$(echo "parseHTMLContent" | _sanitize)"
  assertEquals "parse_html_content" "$result"
}

test_uppercase_to_lowercase() {
  result="$(echo "UPPERCASE" | _sanitize)"
  assertEquals "uppercase" "$result"
}

test_mixedCase_to_lowercase() {
  result="$(echo "MiXeD cAsE" | _sanitize)"
  assertEquals "mi_xe_d_c_as_e" "$result"
}

test_spaces_replaced() {
  result="$(echo "hello world" | _sanitize)"
  assertEquals "hello_world" "$result"
}

test_hyphens_replaced() {
  result="$(echo "hello-world-test" | _sanitize)"
  assertEquals "hello_world_test" "$result"
}

test_dots_replaced() {
  result="$(echo "file.name.txt" | _sanitize)"
  assertEquals "file_name_txt" "$result"
}

test_multiple_special_chars() {
  result="$(echo "hello@#$%world!" | _sanitize)"
  assertEquals "hello_world_" "$result"
}

test_consecutive_special_chars() {
  result="$(echo "hello---world" | _sanitize)"
  assertEquals "hello_world" "$result"
}

test_mixed_separators() {
  result="$(echo "hello world-test.file" | _sanitize)"
  assertEquals "hello_world_test_file" "$result"
}

test_numbers_preserved() {
  result="$(echo "test123" | _sanitize)"
  assertEquals "test123" "$result"
}

test_numbers_with_camelCase() {
  result="$(echo "test123CamelCase" | _sanitize)"
  assertEquals "test123_camel_case" "$result"
}

test_numbers_with_special_chars() {
  result="$(echo "test-123-file" | _sanitize)"
  assertEquals "test_123_file" "$result"
}

test_empty_string() {
  result="$(echo "" | _sanitize)"
  assertEquals "" "$result"
}

test_single_character() {
  result="$(echo "a" | _sanitize)"
  assertEquals "a" "$result"
}

test_single_uppercase() {
  result="$(echo "A" | _sanitize)"
  assertEquals "a" "$result"
}

test_only_special_chars() {
  result="$(echo "@#$%^&*()" | _sanitize)"
  assertEquals "_" "$result"
}

test_only_underscores() {
  result="$(echo "___" | _sanitize)"
  assertEquals "_" "$result"
}

test_leading_uppercase() {
  result="$(echo "UpperCase" | _sanitize)"
  assertEquals "upper_case" "$result"
}

test_trailing_special_chars() {
  result="$(echo "test!!!" | _sanitize)"
  assertEquals "test_" "$result"
}

test_leading_special_chars() {
  result="$(echo "!!!test" | _sanitize)"
  assertEquals "_test" "$result"
}

test_variable_name() {
  result="$(echo "myVariableName" | _sanitize)"
  assertEquals "my_variable_name" "$result"
}

test_class_name() {
  result="$(echo "MyHTTPClientClass" | _sanitize)"
  assertEquals "my_http_client_class" "$result"
}

# shellcheck disable=SC1091
. shunit2
