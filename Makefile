# include tools/hex-package.mk

.PHONY: test-code
test-code:
	mix cover.lint

.PHONY: analyze-code
analyze-code:
	mix format --check-formatted --dry-run
	mix credo --strict
	mix dialyzer