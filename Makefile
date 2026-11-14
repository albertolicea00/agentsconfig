.PHONY: help install install-git uninstall-git status-git test-git scan-git \
        install-agents push-agents pull-agents install-skills status-agents

help: ## Show all commands
	@echo ""
	@printf "\033[1m── Full Setup ──────────────────────────────────────\033[0m\n"
	@printf "    \033[36m%-28s\033[0m %s\n" "install" "Install global Git hooks and agent configs + skills"
	@echo ""
	@printf "\033[1m── Git Security (git/) ─────────────────────────────\033[0m\n"
	@$(MAKE) -C git help --no-print-directory
	@echo ""
	@printf "\033[1m── Global Agents (agents/) ─────────────────────────\033[0m\n"
	@$(MAKE) -C agents help --no-print-directory
	@echo ""

install: install-git install-agents

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

# ── Agents targets ────────────────────────────────────────────────────────────

install-agents:
	@$(MAKE) -C agents install --no-print-directory

push-agents:
	@$(MAKE) -C agents push --no-print-directory

pull-agents:
	@$(MAKE) -C agents pull --no-print-directory

install-skills:
	@$(MAKE) -C agents install-skills --no-print-directory

status-agents:
	@$(MAKE) -C agents status --no-print-directory
