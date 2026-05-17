---
name: trello-board
description: Trello board and card management
license: MIT
compatibility: opencode
---

# Trello Board management skill

Manage Trello boards, lists, and cards using the built-in Trello MCP tools.

## Boards

| Operation | Tool |
|---|---|
| List all boards | `trello_list_boards` |
| Get active board info | `trello_get_active_board_info` |

## Lists

| Operation | Tool |
|---|---|
| Get board lists | `trello_get_lists` (pass boardId) |
| Add list to board | `trello_add_list_to_board` (pass name) |

## Cards

| Operation | Tool |
|---|---|
| Get card details | `trello_get_card` (pass cardId) |
| List cards in a list | `trello_get_cards_by_list_id` (pass listId) |
| Create card | `trello_add_card_to_list` (pass listId, name) |
| Move card | `trello_move_card` (pass cardId, listId) |
| Update card | `trello_update_card_details` (pass cardId) |
| Archive card | `trello_archive_card` (pass cardId) |
| Assign member | `trello_assign_member_to_card` (pass cardId, memberId) |

## Labels

| Operation | Tool |
|---|---|
| Get board labels | `trello_get_board_labels` |
| Create label | `trello_create_label` (pass name, color) |
| Update label | `trello_update_label` (pass labelId) |

## Checklists

| Operation | Tool |
|---|---|
| Get card checklists | `trello_get_checklist_items` / `trello_get_checklist_by_name` |
| Create checklist | `trello_create_checklist` (pass cardId, name) |
| Add checklist item | `trello_add_checklist_item` (pass text, checkListName) |
| Update checklist item | `trello_update_checklist_item` (pass cardId, checkItemId, state) |

## Comments

| Operation | Tool |
|---|---|
| Get card comments | `trello_get_card_comments` (pass cardId) |
| Add comment | `trello_add_comment` (pass cardId, text) |
| Update comment | `trello_update_comment` (pass commentId, text) |
| Delete comment | `trello_delete_comment` (pass commentId) |

## Attachments

| Operation | Tool |
|---|---|
| Attach file from URL | `trello_attach_file_to_card` (pass cardId, fileUrl) |
| Attach image from URL | `trello_attach_image_to_card` (pass cardId, imageUrl) |

## Usage Examples

User: "What boards do I have?"
1. List boards with `trello_list_boards`

User: "Add a card to my TODO list"
1. Get the TODO list ID with `trello_get_lists`
2. Create card with `trello_add_card_to_list` (pass listId, name)

User: "Move card X to Done"
1. Find the card ID with `trello_get_cards_by_list_id`
2. Get the Done list ID with `trello_get_lists`
3. Move card with `trello_move_card` (pass cardId, listId)

User: "What cards are in Doing?"
1. Get the Doing list ID with `trello_get_lists`
2. List cards with `trello_get_cards_by_list_id` (pass listId)

User: "Comment a card then move it to Blocked"
1. Find card ID with `trello_get_cards_by_list_id`
2. Add comment with `trello_add_comment` (pass cardId, text)
3. Get Blocked list ID with `trello_get_lists`
4. Move card with `trello_move_card` (pass cardId, listId)

## Tips

- List IDs can be found by listing boards then getting lists for the active board
- Card IDs can be found by listing cards in a list
- Use consistent naming conventions for cards to make them easier to find and manage
- Cards support markdown in descriptions
