# OpenCode Trello Board

Trello board and card management for OpenCode projects. Provides a skill that uses the Trello MCP server to interact with boards, lists, cards, labels, checklists, and comments.

## Architecture

```plaintext
OpenCode Skill (trello-board)
  └─ SKILL.md — describes available Trello MCP tools to the agent

Trello MCP Server
  └─ Provides tools like trello_get_card, trello_add_card_to_list, etc.
```

## Setup

```bash
./trello-board/scripts/setup.sh
```

This will:

1. Validate that the current project has `.opencode/`
2. Copy `SKILL.md` to `.opencode/skills/trello-board/`
3. Write a `.version` file for future update checks

### Prerequisites

The Trello MCP server must be configured in your `opencode.json`. The skill relies on MCP tools being available — no additional environment variables or custom tools are needed.

## Available Operations

The skill exposes Trello operations via MCP tools. Key operations include:

### Boards
- `trello_list_boards` — List all Trello boards
- `trello_get_active_board_info` — Get active board details

### Lists
- `trello_get_lists` — Get lists on a board
- `trello_add_list_to_board` — Add a new list

### Cards
- `trello_get_card` — Get card details
- `trello_get_cards_by_list_id` — List cards in a list
- `trello_add_card_to_list` — Create a new card
- `trello_move_card` — Move a card to another list
- `trello_update_card_details` — Update a card
- `trello_archive_card` — Archive a card
- `trello_assign_member_to_card` — Assign a member to a card

### Labels
- `trello_get_board_labels` — Get board labels
- `trello_create_label` — Create a label
- `trello_update_label` — Update a label

### Checklists
- `trello_create_checklist` — Create a checklist
- `trello_add_checklist_item` — Add a checklist item
- `trello_update_checklist_item` — Update checklist item state

### Comments
- `trello_get_card_comments` — Get card comments
- `trello_add_comment` — Add a comment
- `trello_update_comment` — Update a comment
- `trello_delete_comment` — Delete a comment

### Attachments
- `trello_attach_file_to_card` — Attach a file from a URL
- `trello_attach_image_to_card` — Attach an image from a URL

## OpenCode Integration

The skill is automatically activated when the agent detects Trello-related requests:

```bash
opencode run "list my boards"
opencode run "list cards in my TODO list"
opencode run "create a card called 'Fix login bug' in the Doing list"
opencode run "move card X to Done"
```

## Version Control

The installed version is tracked in `.opencode/skills/trello-board/.version`. Re-running `setup.sh` skips installation if the version is already up to date. Use `--force` to reinstall regardless.

```bash
./trello-board/scripts/setup.sh --force
```
