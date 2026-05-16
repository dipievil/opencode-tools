---
name: trello-board
description: Trello board and card management
license: MIT
compatibility: opencode
---

# Trello Board management skill

Manage a specific Trello board, its lists, and cards using the `trello-board-tool`.

## Available Tools

- **trello-board-tool**: Manage Trello boards, lists, and cards

### Operations Reference

**Cards**

| Operation | Command |
|---|---|
| Get card details | `trello-board-tool get-card --card-id {card_id}` |
| Search cards by name | `trello-board-tool search-cards --query "{search_query}"` |
| List cards in a list | `trello-board-tool get-cards --list-id {list_id}` |
| Create card | `trello-board-tool create-card --name "Title" --desc "Desc" --list-id {list_id}` |
| Update card | `trello-board-tool update-card --card-id {card_id} --name "Title" --desc "Desc"` |
| Move card | `trello-board-tool move --card-id {card_id} --list-id {new_list_id}` |

**Labels**

| Operation | Command |
|---|---|
| Create label | `trello-board-tool add-label --name "Label" --color {color}` |
| Set label on card | `trello-board-tool set-label --card-id {card_id} --label-id {label_id}` |
| Remove label from card | `trello-board-tool remove-label --card-id {card_id} --label-id {label_id}` |

**Lists, Checklists & Comments**

| Operation | Command |
|---|---|
| Get all lists | `trello-board-tool get-lists` |
| Get checklists | `trello-board-tool get-checklists --card-id {card_id}` |
| Get comments | `trello-board-tool get-comments --card-id {card_id}` |
| Add comment | `trello-board-tool add-comment --card-id {card_id} --text "Text"` |
| Update comment | `trello-board-tool update-comment --comment-id {comment_id} --text "Text"` |

## Usage Examples

User: "Add a card to my TODO list"
1. Create card with `trello-board-tool create-card --name "Card title" --desc "Card description" --list-id {list_id}`

User: "Move card X to Done"
1. Find card by name or ID with `trello-board-tool get-cards --list-id {list_id}`
2. Move card with `trello-board-tool move --card-id {card_id} --list-id {done_list_id}`

User: "What cards are in Doing?"
1. Get cards in Doing list with `trello-board-tool get-cards --list-id {doing_list_id}`

User: "Update card X description"
1. Find card by name or ID with `trello-board-tool get-cards --list-id {list_id}`
2. Update card with `trello-board-tool update-card --card-id {card_id} --desc "New description"`

User: "Comment a card then move it to Blocked"
1. Find card by name or ID with `trello-board-tool get-cards --list-id {list_id}`
2. Comment card with `trello-board-tool add-comment --card-id {card_id} --text "This is a comment"`
3. Move card with `trello-board-tool move --card-id {card_id} --list-id {blocked_list_id}`

## Environment Setup

Required variables (`TRELLO_API_KEY`, `TRELLO_TOKEN`, `TRELLO_BOARD_ID`) must be set before using the tool. Column ID variables are optional and used to reference lists by name.

```bash
export TRELLO_API_KEY="your_api_key"
export TRELLO_TOKEN="your_token"
export TRELLO_BOARD_ID="your_board_id"
export TRELLO_BACKLOG_COL="your_backlog_column_id"
export TRELLO_TODO_COL="your_todo_column_id"
export TRELLO_DOING_COL="your_doing_column_id"
export TRELLO_TESTING_COL="your_testing_column_id"
export TRELLO_CODE_REVIEW_COL="your_code_review_column_id"
export TRELLO_DONE_COL="your_done_column_id"
export TRELLO_BLOCKED_COL="your_blocked_column_id"
export TRELLO_CANCELLED_COL="your_cancelled_column_id"
```

If `TRELLO_API_KEY`, `TRELLO_TOKEN`, or `TRELLO_BOARD_ID` are missing or invalid, inform the user that the credentials are not configured and ask them to set the required environment variables before retrying.

## Tips

- List IDs can be found in the Trello board URL or by using the `trello-board-tool get-lists` command.
- Card IDs can be found in the card URL or by using the `trello-board-tool get-cards` command for the relevant list.
- Use consistent naming conventions for cards to make them easier to find and manage.
- Cards support markdown in descriptions
- Labels, due dates, and attachments available

## RULES

- If trello-board-tool returns an error, respond with "Sorry, I couldn't perform that action." and stop imediately.
