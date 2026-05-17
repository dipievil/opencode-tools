---
name: trello-board
description: Trello board and card management
license: MIT
compatibility: opencode
---

# Trello Board management skill

Manage a specific Trello board, its lists, and cards using the `trello-board-tool`.

## Available Tools

- **trello-board-tool**: Manages Trello boards, lists, cards, labels, checklists, and comments by calling the Trello REST API directly.

### Tool Functions

| Function | Description | Arguments |
|---|---|---|
| `getCard` | Get card details by ID | `cardId` |
| `searchCards` | Search cards by name query | `query` |
| `getLists` | Get all lists on the board | (none) |
| `move` | Move card to another list | `cardId`, `listId` |
| `createCard` | Create a new card | `name`, `desc`, `listId` |
| `updateCard` | Update card name/description | `cardId`, `name`, `desc` |
| `list` | List all cards in a list | `listId` |
| `setLabel` | Attach a label to a card | `cardId`, `labelId` |
| `removeLabel` | Remove a label from a card | `cardId`, `labelId` |
| `createLabel` | Create a new label on the board | `name`, `color` |
| `checklists` | Get checklists on a card | `cardId` |
| `comments` | Get comments on a card | `cardId` |
| `addComment` | Add a comment to a card | `cardId`, `text` |
| `updateComment` | Update an existing comment | `commentId`, `cardId`, `text` |

## Usage Examples

User: "Add a card to my TODO list"
1. Look up the TODO list ID with `getLists`
2. Create card with `createCard(name="Card title", desc="Card description", listId=<list_id>)`

User: "Move card X to Done"
1. Find the card ID with `list(listId=<list_id>)`
2. Move card with `move(cardId=<card_id>, listId=<done_list_id>)`

User: "What cards are in Doing?"
1. List cards with `list(listId=<doing_list_id>)`

User: "Update card X description"
1. Find card ID with `list(listId=<list_id>)`
2. Update card with `updateCard(cardId=<card_id>, desc="New description")`

User: "Comment on a card then move it to Blocked"
1. Find card ID with `list(listId=<list_id>)`
2. Add comment with `addComment(cardId=<card_id>, text="This is a comment")`
3. Move card with `move(cardId=<card_id>, listId=<blocked_list_id>)`

## Environment Setup

The tool loads credentials automatically from `.opencode/skills/trello-board/.env` (created by `setup.sh`). Edit that file to configure your settings.

```bash
TRELLO_API_KEY=your_trello_api_key_here
TRELLO_TOKEN=your_trello_token_here
TRELLO_BOARD_ID=your_trello_board_id_here
```

Column ID variables are optional and used to reference lists by name:

```bash
TRELLO_BACKLOG_COL=your_backlog_column_id
TRELLO_TODO_COL=your_todo_column_id
TRELLO_DOING_COL=your_doing_column_id
TRELLO_TESTING_COL=your_testing_column_id
TRELLO_CODE_REVIEW_COL=your_code_review_column_id
TRELLO_DONE_COL=your_done_column_id
TRELLO_BLOCKED_COL=your_blocked_column_id
TRELLO_CANCELLED_COL=your_cancelled_column_id
```

If `TRELLO_API_KEY`, `TRELLO_TOKEN`, or `TRELLO_BOARD_ID` are missing or invalid, inform the user that the credentials are not configured and ask them to check `.opencode/skills/trello-board/.env` before retrying.

## Tips

- Find list IDs using `getLists`, or extract from the Trello board URL.
- Find card IDs using `list(listId=<list_id>)`, or extract from the card URL.
- Use consistent naming conventions for cards to make them easier to find and manage.
- Cards support markdown in descriptions.
- Labels, due dates, and attachments available.

## RULES

- If the tool returns an error, respond with "Sorry, I couldn't perform that action." and stop immediately.
