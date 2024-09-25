include .env

.EXPORT_ALL_VARIABLES:
MAKEFLAGS += --no-print-directory

default:
	@forge fmt && forge build

clean:
	@forge clean && make default

# Always keep Forge up to date
install:
	foundryup
	rm -rf node_modules
	pnpm i

test:
	@forge test

test-f-%:
	@FOUNDRY_MATCH_TEST=$* make test

test-c-%:
	@FOUNDRY_MATCH_CONTRACT=$* make test

test-m-%:
	@network=$$(echo "$*" | cut -d'-' -f1); \
	script_path="test/$$network/"; \
	FOUNDRY_TEST=$$script_path make test; \


coverage:
	@forge coverage --report lcov
	@lcov --remove lcov.info 'test/*' -o lcov.info --ignore-errors unused
	@genhtml lcov.info --output-directory coverage

.PHONY: test coverage