.PHONY: test lint check dry-run

test:  ## Run cron validation suite
	@bash scripts/test-crons.sh

lint:  ## Shellcheck + Python syntax only
	@bash scripts/test-crons.sh --quick

check: lint test  ## Full pre-deploy check

dry-run:  ## Dry-run key generators
	python3 scripts/generate-daily-note.py --dry-run
	@echo "---"
	python3 scripts/brief-modules/fetch_human_todo.py --test

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
