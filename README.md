<!-- # >> agentsconfig -->

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="ascii-art-text-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="ascii-art-text-light.png">
  <img alt="agentsconfig" src="ascii-art-text-light.png">
  <!-- Credits to [patorjk.com TAAG](https://patorjk.com/software/taag/#p=display&f=Big+Money-sw&t=config&x=none&v=4&h=0&w=80&we=false) for the `ascii-art-text`, font `Big Money-sw`. -->
</picture>

My personal collection of global configurations, security hooks, and environment setups — the ones I actually use.  
Protect commits, harden tools, keep every machine in sync. *code, vibe, repeat...*

![Git](https://img.shields.io/badge/Git-Hooks-F05032?logo=git&logoColor=white)
![Gitleaks](https://img.shields.io/badge/Gitleaks-8.30+-blue)
![detect-secrets](https://img.shields.io/badge/Yelp-detect--secrets-d92323)
![Shell](https://img.shields.io/badge/Shell-Scripts-4EAA25?logo=gnubash&logoColor=white)


## See [`git/`](git/README.md) · [`agents/`](agents/README.md)

## What is this?

A single home for machine-wide developer and AI-agent configurations:

- **`git/`** — Global Git hooks (`pre-commit`, `pre-push`) powered by **Gitleaks** + **detect-secrets** (100% local and offline). Blocks API keys, connection URIs (`postgres://<user>:<pass>@<ip>`), disguised high-entropy passwords, and hardcoded public IPv4 addresses across all repositories.
- **`agents/`** — Global AI coding agent configurations (`.claude`, `.codex`, `.codexbar`, `.continue`, `.copilot`, `.gemini`) and global skill lockfiles (`skills-lock.json`, `.agents/.skill-lock.json`) with sync (`push`/`pull`) and installer scripts.

## Usage

```bash
make help            # list all commands
make install         # install global Git hooks and agent configs + skills
```

**Global Git Security (`git/`):**
```bash
make install-git     # install gitleaks + detect-secrets and activate global Git hooks
make status-git      # check active global hooksPath and scanner versions
make test-git        # run self-test against disguised secrets, DB URIs, and public IPs
make scan-git DIR=.  # audit a repository or directory on demand
make uninstall-git   # remove global core.hooksPath
```

**Global Agent Configs & Skills (`agents/`):**
```bash
make install-agents  # install global agent configs to $HOME + install skills
make push-agents     # copy tracked agent configs from repo to $HOME (configs only)
make pull-agents     # pull tracked agent configs and skill lockfiles from $HOME
make install-skills  # install missing global skills from lockfiles via npx skills
make status-agents   # check sync status between repo and $HOME
```


## Related repos

- [**albertolicea00/agentskills**](https://github.com/albertolicea00/agentskills) — my collection of agent skills.
- [**albertolicea00/agentscripts**](https://github.com/albertolicea00/agentscripts) — Google Colab notebooks and local shell scripts for media & automation.
- [**albertolicea00/clawflows**](https://github.com/albertolicea00/clawflows) — the workflow half of this setup: ready-to-use OpenClaw workflows for multi-step tasks you can fire from a chat app. *code, vibe, repeat...*

## License

[Unlicense](UNLICENSE) — Powered by @albertolicea00 and his unstoppable AI‑agents

> 🤖 Many of these configurations and scripts are **AI‑generated** and then reviewed & refined by me. The AI proposes, I approve — everything passes through manual review before being used.
