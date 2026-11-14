.PHONY: help install-git uninstall-git status-git test-git scan-git

help: ## Show all commands
	@echo ""
	@printf "\033[1m── Git Security (git/) ─────────────────────────────\033[0m\n"
	@$(MAKE) -C git help --no-print-directory
	@echo ""

# ── Git targets ───────────────────────────────────────────────────────────────

install-git:
	@$(MAKE) -C git install --no-print-directory

uninstall-git:
	@$(MAKE) -C git uninstall --no-print-directory

status-git:
	@$(MAKE) -C git status --no-print-directory

test-git:
	@$(MAKE) -C git test --no-print-directory

scan-git:
	@$(MAKE) -C git scan DIR="$(DIR)" --no-print-directory
