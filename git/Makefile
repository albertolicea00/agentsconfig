.PHONY: help install uninstall status test scan

help:
	@echo ""
	@echo "  Git Security Hooks (Gitleaks + detect-secrets)"
	@printf "    \033[36m%-28s\033[0m %s\n" "install-git"   "Install deps and set global git core.hooksPath"
	@printf "    \033[36m%-28s\033[0m %s\n" "uninstall-git" "Remove global git core.hooksPath"
	@printf "    \033[36m%-28s\033[0m %s\n" "status-git"    "Show active global hooksPath and scanner versions"
	@printf "    \033[36m%-28s\033[0m %s\n" "test-git"      "Run self-test with disguised secrets, URIs, and IPs"
	@printf "    \033[36m%-28s\033[0m %s\n" "scan-git"      "Scan a target repo (DIR=/path/to/repo, default: pwd)"

install:
	@bash scripts/install.sh

uninstall:
	@bash scripts/uninstall.sh

status:
	@echo "core.hooksPath : $$(git config --global --get core.hooksPath || echo '(not set)')"
	@echo "gitleaks       : $$(command -v gitleaks || echo '(missing)') $$(gitleaks version 2>/dev/null || true)"
	@echo "detect-secrets : $$(command -v detect-secrets || echo '(missing)') $$(detect-secrets --version 2>/dev/null || true)"

test:
	@bash scripts/test-secrets.sh

scan:
	@target="$${DIR:-$$(pwd)}"; \
	echo "==> Scanning $$target with Gitleaks + custom rules..."; \
	gitleaks dir "$$target" --redact --verbose --config="$(CURDIR)/gitleaks.toml"
