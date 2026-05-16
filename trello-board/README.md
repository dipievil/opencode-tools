# OpenCode Trello Board

Trello board and card management for OpenCode projects. Provides a skill, a custom tool, and a shell script CLI to interact with Trello boards, lists, cards, labels, checklists, and comments.

## Architecture

```plaintext
OpenCode Skill (trello-board)
  └─ SKILL.md — describes available operations to the agent
  └─ scripts/trello-call.sh — shell CLI that wraps Trello REST API

OpenCode Custom Tool (trello-board-tool)
  └─ trello-board-tool.ts — TypeScript tool calling trello-call.sh

Direct CLI:
  .opencode/skills/trello-board/scripts/trello-call.sh <command> [flags]
```

## Setup

```bash
./trello-board/scripts/setup.sh
```

This will:

1. Validate that the current project has `.opencode/`
2. Create `.opencode/skills/trello-board/` with `SKILL.md` and `scripts/trello-call.sh`
3. Install the `trello-board-tool` as a project-local custom tool in `.opencode/tools/`
4. Write a `.version` file for future update checks

## Environment Variables

The tool requires the following environment variables. `TRELLO_CALL_SCRIPT_PATH` is written automatically by `setup.sh` into `.opencode/skills/trello-board/.env`. Edit that file to add your credentials.

| Variable | Description | Set by |
|---|---|---|
| `TRELLO_CALL_SCRIPT_PATH` | Absolute path to the installed `trello-call.sh` | `setup.sh` (automatic) |
| `TRELLO_API_KEY` | Your Trello API key | Manual |
| `TRELLO_TOKEN` | Your Trello OAuth token | Manual |
| `TRELLO_BOARD_ID` | The default Trello board ID to operate on | Manual |

```bash
# .opencode/skills/trello-board/scripts/.env
TRELLO_CALL_SCRIPT_PATH=/path/to/.opencode/skills/trello-board/scripts/trello-call.sh
TRELLO_API_KEY=your_api_key
TRELLO_TOKEN=your_token
TRELLO_BOARD_ID=your_board_id
```

## Available Operations

### Cards

| Operation | Description |
|---|---|
| `get-card --card-id <id>` | Get card details |
| `search-cards --query "<text>"` | Search cards by name |
| `get-cards --list-id <id>` | List all cards in a list |
| `create-card --name "<title>" --desc "<desc>" --list-id <id>` | Create a new card |
| `update-card --card-id <id> --name "<title>" --desc "<desc>"` | Update a card |
| `move --card-id <id> --list-id <id>` | Move a card to another list |

### Lists

| Operation | Description |
|---|---|
| `get-lists` | Get all lists on the board |

### Labels

| Operation | Description |
|---|---|
| `add-label --name "<name>" --color <color>` | Create a label |
| `set-label --card-id <id> --label-id <id>` | Attach a label to a card |
| `remove-label --card-id <id> --label-id <id>` | Remove a label from a card |

### Checklists & Comments

| Operation | Description |
|---|---|
| `get-checklists --card-id <id>` | Get checklists on a card |
| `get-comments --card-id <id>` | Get comments on a card |
| `add-comment --card-id <id> --text "<text>"` | Add a comment to a card |
| `update-comment --comment-id <id> --text "<text>"` | Update a comment |

## Tools

### trello-call.sh

Direct shell CLI for scripting or manual use:

```bash
.opencode/skills/trello-board/scripts/trello-call.sh get-lists
.opencode/skills/trello-board/scripts/trello-call.sh get-cards --list-id <id>
.opencode/skills/trello-board/scripts/trello-call.sh create-card --name "Fix bug" --list-id <id>
.opencode/skills/trello-board/scripts/trello-call.sh move --card-id <id> --list-id <done-id>
```

### OpenCode Integration

The skill is automatically activated when the agent detects Trello-related requests:

```bash
opencode run "list cards in my TODO list"
opencode run "create a card called 'Fix login bug' in the Doing list"
opencode run "move card X to Done"
opencode run "add a comment to card Y saying the fix is deployed"
```

## Version Control

The installed version is tracked in `.opencode/skills/trello-board/.version`. Re-running `setup.sh` skips installation if the version is already up to date. Use `--force` to reinstall regardless.

```bash
./trello-board/scripts/setup.sh --force
```
