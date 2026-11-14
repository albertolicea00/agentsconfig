.PHONY: help install push pull install-skills status

help:
	@echo ""
	@echo "  Global Agent Configs & Skills (agents/)"
	@printf "    \033[36m%-28s\033[0m %s\n" "install-agents" "Install global agent configs to \$$HOME and install skills"
	@printf "    \033[36m%-28s\033[0m %s\n" "push-agents"    "Copy tracked agent configs from repo to \$$HOME (configs only)"
	@printf "    \033[36m%-28s\033[0m %s\n" "pull-agents"    "Pull tracked agent configs and lockfiles from \$$HOME into repo"
	@printf "    \033[36m%-28s\033[0m %s\n" "install-skills" "Install global skills from lockfiles via npx skills"
	@printf "    \033[36m%-28s\033[0m %s\n" "status-agents"  "Check sync status between repo and \$$HOME"

install:
	@bash scripts/install.sh

push:
	@bash scripts/install.sh --configs-only

pull:
	@bash scripts/pull.sh

install-skills:
	@bash scripts/install-skills.sh $(ARGS)

status:
	@bash scripts/status.sh
