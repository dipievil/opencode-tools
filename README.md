# opencode-tools

![License](https://img.shields.io/github/license/dipievil/opencode-tools)
![Drone CI](https://img.shields.io/badge/ci-drone-blue)

Tooling collection for OpenCode workflows.

## What is in this repository

- `job-manager-system/`: cron job manager toolkit (scripts, templates, and tool integration)
- `telegram-notify/`: Telegram notification tool and setup scripts

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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Licensed under the MIT License. See [LICENSE](LICENSE).
