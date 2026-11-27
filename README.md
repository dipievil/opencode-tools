# opencode-tools

![License](https://img.shields.io/github/license/dipievil/opencode-tools)
![Drone CI](https://img.shields.io/badge/ci-drone-blue)

Tooling collection for OpenCode workflows.

## What is in this repository

- `job-manager-system/`: cron job manager toolkit (scripts, templates, and tool integration)
- `telegram-notify/`: Telegram notification tool and setup scripts
- `openchamber/commands/`: global OpenCode/OpenChamber slash commands

## Requirements

- Bun 1.2+
- OpenCode installed and configured

## Installation

```bash
bun install
```

## Usage

### Typecheck

```bash
bun run typecheck
```

### Run tests

```bash
bun test
```

### Cron job manager setup

```bash
./job-manager-system/scripts/setup.sh
```

### Telegram notifier setup

```bash
./telegram-notify/scripts/setup.sh
```

### OpenChamber commands

The `openchamber/commands/` folder holds the global slash commands used in OpenCode/OpenChamber. Each Markdown file becomes a command named after the file; its front matter sets the description and whether it runs in a subagent.

| Command | Description |
| --- | --- |
| `/code-review` | Reviews the oldest unreviewed open GitHub PR, comments inline on issues, creates backlog cards for out-of-scope findings, and notifies Telegram. |
| `/task-management` | Audits and rebalances the Board cards for the `retro-shmup` project and reports blockers on Telegram. |

Plannotator commands are intentionally excluded; Plannotator is provided as an extension, not as a slash command in this repository.

Copy them to the global commands directory to make them available in every project:

```bash
mkdir -p ~/.config/opencode/commands
cp openchamber/commands/*.md ~/.config/opencode/commands/
```

`code-review` and `task-management` need GitHub/Trello access and the Telegram notifier configured above.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Licensed under the MIT License. See [LICENSE](LICENSE).
