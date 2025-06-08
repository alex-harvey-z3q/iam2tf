.PHONY: test _shellcheck _shunit2

test: _shellcheck _shunit2

_shellcheck:
	shellcheck iam2tf.sh

_shunit2:
	bash shunit2/test_*.sh
