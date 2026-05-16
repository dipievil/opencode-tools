---
name: trello-board
description: Trello board and card management
license: MIT
compatibility: opencode
---

# Trello Board management skill

Manage a specific Trello board, its lists, and cards using the `trello-tool`.

## Available Tools

- **trello-tool**: Manage Trello boards, lists, and cards

### Common Operations

#### Get Card
```
trello-tool get-card --card-id {card_id}
```

#### Search Cards
```
trello-tool search-cards --query "{search_query}"
```

#### Get Lists
```
trello-tool get-lists
```

#### Get Cards in List
```
trello-tool get-cards --list-id {list_id}
```

#### Move Card
```
trello-tool move --card-id {card_id} --list-id {new_list_id}
```

#### Create Card
```
trello-tool create-card --name "Card title" --desc "Card description" --list-id {list_id}
```

#### Update Card
```
trello-tool update-card --card-id {card_id} --name "New title" --desc "New description"
```

#### Set Label
```
trello-tool set-label --card-id {card_id} --label-id {label_id}
```

#### Remove Label
```
trello-tool remove-label --card-id {card_id} --label-id {label_id}
```

#### Create Label
```
trello-tool add-label --name "Label name" --color {color}
```

#### Get Checklists
```
trello-tool get-checklists --card-id {card_id}
```

#### Get Comments
```
trello-tool get-comments --card-id {card_id}
```

#### Add Comment
```
trello-tool add-comment --card-id {card_id} --text "Comment text"
```

#### Update Comment
```
trello-tool update-comment --comment-id {comment_id} --text "New comment text"
```

## Usage Examples

User: "Add a card to my TODO list"
1. Create card with `trello-tool create-card --name "Card title" --desc "Card description" --list-id {list_id}`

User: "Move card X to Done"
1. Find card by name or ID with `trello-tool get-cards --list-id {list_id}`
2. Move card with `trello-tool move --card-id {card_id} --list-id {done_list_id}`

User: "What cards are in Doing?"
1. Get cards in Doing list with `trello-tool get-cards --list-id {doing_list_id}`

User: "Update card X description"
1. Find card by name or ID with `trello-tool get-cards --list-id {list_id}`
2. Update card with `trello-tool update-card --card-id {card_id} --desc "New description"`

User: "Comment a card then move it to Blocked"
1. Find card by name or ID with `trello-tool get-cards --list-id {list_id}`
2. Comment card with `trello-tool add-comment --card-id {card_id} --text "This is a comment"`
3. Move card with `trello-tool move --card-id {card_id} --list-id {blocked_list_id}`

## Environment Setup

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

## Tips

- List IDs can be found in the Trello board URL or by using the `trello-tool get-lists` command.
- Card IDs can be found in the card URL or by using the `trello-tool get-cards` command for the relevant list.
- Use consistent naming conventions for cards to make them easier to find and manage.
- Cards support markdown in descriptions
- Labels, due dates, and attachments available

## RULES

- If trello-tool returns an error, respond with "Sorry, I couldn't perform that action." and stop imediately.
