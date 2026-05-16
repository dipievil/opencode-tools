#!/usr/bin/env bash
# trello-call.sh - Trello board, list, and card management CLI
set -o errexit
set -o nounset
set -o pipefail

# ---------------------------------------------------------------------------
# Dependencies check
# ---------------------------------------------------------------------------
for cmd in curl jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' is required but not installed." >&2
    echo "  Install with: sudo apt install $cmd  (Debian/Ubuntu)" >&2
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# Load .env if present (project root or skill directory)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  set -o allexport
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/.env"
  set +o allexport
fi

# ---------------------------------------------------------------------------
# Configuration (from environment)
# ---------------------------------------------------------------------------
TRELLO_API_KEY="${TRELLO_API_KEY:-}"
TRELLO_TOKEN="${TRELLO_TOKEN:-}"
TRELLO_BOARD_ID="${TRELLO_BOARD_ID:-}"

BASE_URL="https://api.trello.com/1"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
require_credentials() {
  if [[ -z "$TRELLO_API_KEY" || -z "$TRELLO_TOKEN" ]]; then
    echo "ERROR: TRELLO_API_KEY and TRELLO_TOKEN must be set." >&2
    exit 1
  fi
}

auth_params() {
  echo "key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}"
}

api_get() {
  local path="$1"
  local extra_params="${2:-}"
  local url
  url="${BASE_URL}${path}?$(auth_params)${extra_params:+&$extra_params}"
  curl -s -f "$url"
}

api_post() {
  local path="$1"
  local data="$2"
  curl -s -f -X POST \
    -H "Content-Type: application/json" \
    "${BASE_URL}${path}?$(auth_params)" \
    -d "$data"
}

api_put() {
  local path="$1"
  local data="$2"
  curl -s -f -X PUT \
    -H "Content-Type: application/json" \
    "${BASE_URL}${path}?$(auth_params)" \
    -d "$data"
}

api_delete() {
  local path="$1"
  curl -s -f -X DELETE "${BASE_URL}${path}?$(auth_params)"
}

# Parse --flag value pairs from remaining args into named variables.
# Usage: parse_args card_id list_id -- "$@"
parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --card-id)      CARD_ID="$2";      shift 2 ;;
      --list-id)      LIST_ID="$2";      shift 2 ;;
      --label-id)     LABEL_ID="$2";     shift 2 ;;
      --comment-id)   COMMENT_ID="$2";   shift 2 ;;
      --board-id)     BOARD_ID="$2";     shift 2 ;;
      --name)         NAME="$2";         shift 2 ;;
      --desc)         DESC="$2";         shift 2 ;;
      --text)         TEXT="$2";         shift 2 ;;
      --color)        COLOR="$2";        shift 2 ;;
      --query)        QUERY="$2";        shift 2 ;;
      *) echo "ERROR: Unknown flag '$1'" >&2; exit 1 ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------
cmd_get_card() {
  local CARD_ID=""
  parse_flags "$@"
  require_credentials
  [[ -n "$CARD_ID" ]] || { echo "ERROR: --card-id required." >&2; exit 1; }
  api_get "/cards/${CARD_ID}" \
    | jq '{id, name, desc, due, url, idList, idBoard, idLabels, idChecklists, shortUrl}'
}

cmd_search_cards() {
  local QUERY=""
  parse_flags "$@"
  require_credentials
  [[ -n "$QUERY" ]] || { echo "ERROR: --query required." >&2; exit 1; }
  local board_param=""
  [[ -n "${TRELLO_BOARD_ID:-}" ]] && board_param="idBoards=${TRELLO_BOARD_ID}"
  api_get "/search" "query=$(jq -rn --arg q "$QUERY" '$q | @uri')&modelTypes=cards${board_param:+&$board_param}" \
    | jq '[.cards[] | {id, name, desc, idList, url, shortUrl}]'
}

cmd_get_lists() {
  local BOARD_ID=""
  parse_flags "$@"
  require_credentials
  local board_id="${BOARD_ID:-${TRELLO_BOARD_ID:-}}"
  [[ -n "$board_id" ]] || { echo "ERROR: --board-id required (or set TRELLO_BOARD_ID)." >&2; exit 1; }
  api_get "/boards/${board_id}/lists" "fields=id,name" \
    | jq '[.[] | {id, name}]'
}

cmd_get_cards() {
  local LIST_ID=""
  parse_flags "$@"
  require_credentials
  [[ -n "$LIST_ID" ]] || { echo "ERROR: --list-id required." >&2; exit 1; }
  api_get "/lists/${LIST_ID}/cards" "fields=id,name,desc,due,url,idLabels,idChecklists" \
    | jq '[.[] | {id, name, desc, due, url, idLabels, idChecklists}]'
}

cmd_move() {
  local CARD_ID="" LIST_ID=""
  parse_flags "$@"
  require_credentials
  [[ -n "$CARD_ID" ]] || { echo "ERROR: --card-id required." >&2; exit 1; }
  [[ -n "$LIST_ID" ]] || { echo "ERROR: --list-id required." >&2; exit 1; }
  api_put "/cards/${CARD_ID}" "{\"idList\":\"${LIST_ID}\"}" \
    | jq '{id, name, idList, url}'
}

cmd_create_card() {
  local LIST_ID="" NAME="" DESC=""
  parse_flags "$@"
  require_credentials
  [[ -n "$LIST_ID" ]] || { echo "ERROR: --list-id required." >&2; exit 1; }
  [[ -n "$NAME" ]]    || { echo "ERROR: --name required." >&2; exit 1; }
  local payload
  payload="$(jq -n --arg name "$NAME" --arg desc "${DESC:-}" --arg idList "$LIST_ID" \
    '{name: $name, desc: $desc, idList: $idList}')"
  api_post "/cards" "$payload" | jq '{id, name, url}'
}

cmd_update_card() {
  local CARD_ID="" NAME="" DESC=""
  parse_flags "$@"
  require_credentials
  [[ -n "$CARD_ID" ]] || { echo "ERROR: --card-id required." >&2; exit 1; }
  local payload="{}"
  [[ -n "$NAME" ]] && payload="$(echo "$payload" | jq --arg v "$NAME" '. + {name: $v}')"
  [[ -n "$DESC" ]] && payload="$(echo "$payload" | jq --arg v "$DESC" '. + {desc: $v}')"
  api_put "/cards/${CARD_ID}" "$payload" | jq '{id, name, desc, url}'
}

cmd_set_label() {
  local CARD_ID="" LABEL_ID=""
  parse_flags "$@"
  require_credentials
  [[ -n "$CARD_ID" ]]  || { echo "ERROR: --card-id required." >&2; exit 1; }
  [[ -n "$LABEL_ID" ]] || { echo "ERROR: --label-id required." >&2; exit 1; }
  api_post "/cards/${CARD_ID}/idLabels" "{\"value\":\"${LABEL_ID}\"}" \
    | jq '.'
}

cmd_remove_label() {
  local CARD_ID="" LABEL_ID=""
  parse_flags "$@"
  require_credentials
  [[ -n "$CARD_ID" ]]  || { echo "ERROR: --card-id required." >&2; exit 1; }
  [[ -n "$LABEL_ID" ]] || { echo "ERROR: --label-id required." >&2; exit 1; }
  api_delete "/cards/${CARD_ID}/idLabels/${LABEL_ID}" > /dev/null \
    && echo "{\"removed\":\"${LABEL_ID}\"}"
}

cmd_add_label() {
  local NAME="" COLOR="" BOARD_ID=""
  parse_flags "$@"
  require_credentials
  [[ -n "$NAME" ]]  || { echo "ERROR: --name required." >&2; exit 1; }
  [[ -n "$COLOR" ]] || { echo "ERROR: --color required." >&2; exit 1; }
  local board_id="${BOARD_ID:-${TRELLO_BOARD_ID:-}}"
  [[ -n "$board_id" ]] || { echo "ERROR: --board-id required (or set TRELLO_BOARD_ID)." >&2; exit 1; }
  local payload
  payload="$(jq -n --arg name "$NAME" --arg color "$COLOR" --arg idBoard "$board_id" \
    '{name: $name, color: $color, idBoard: $idBoard}')"
  api_post "/labels" "$payload" | jq '{id, name, color}'
}

cmd_get_checklists() {
  local CARD_ID=""
  parse_flags "$@"
  require_credentials
  [[ -n "$CARD_ID" ]] || { echo "ERROR: --card-id required." >&2; exit 1; }
  api_get "/cards/${CARD_ID}/checklists" \
    | jq '[.[] | {id, name, checkItems: [.checkItems[] | {id, name, state}]}]'
}

cmd_get_comments() {
  local CARD_ID=""
  parse_flags "$@"
  require_credentials
  [[ -n "$CARD_ID" ]] || { echo "ERROR: --card-id required." >&2; exit 1; }
  api_get "/cards/${CARD_ID}/actions" "filter=commentCard" \
    | jq '[.[] | {id, date, text: .data.text, memberCreator: .memberCreator.username}]'
}

cmd_add_comment() {
  local CARD_ID="" TEXT=""
  parse_flags "$@"
  require_credentials
  [[ -n "$CARD_ID" ]] || { echo "ERROR: --card-id required." >&2; exit 1; }
  [[ -n "$TEXT" ]]    || { echo "ERROR: --text required." >&2; exit 1; }
  local payload
  payload="$(jq -n --arg text "$TEXT" '{text: $text}')"
  api_post "/cards/${CARD_ID}/actions/comments" "$payload" \
    | jq '{id, date, text: .data.text}'
}

cmd_update_comment() {
  local COMMENT_ID="" TEXT="" CARD_ID=""
  parse_flags "$@"
  require_credentials
  [[ -n "$COMMENT_ID" ]] || { echo "ERROR: --comment-id required." >&2; exit 1; }
  [[ -n "$CARD_ID" ]]    || { echo "ERROR: --card-id required." >&2; exit 1; }
  [[ -n "$TEXT" ]]       || { echo "ERROR: --text required." >&2; exit 1; }
  local payload
  payload="$(jq -n --arg text "$TEXT" '{text: $text}')"
  api_put "/cards/${CARD_ID}/actions/${COMMENT_ID}/comments" "$payload" \
    | jq '{id, date, text: .data.text}'
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: trello-call.sh <command> [--flag value ...]

Commands:
  get-card        --card-id <id>
  search-cards    --query <text>
  get-lists       [--board-id <id>]
  get-cards       --list-id <id>
  move            --card-id <id> --list-id <id>
  create-card     --list-id <id> --name <text> [--desc <text>]
  update-card     --card-id <id> [--name <text>] [--desc <text>]
  set-label       --card-id <id> --label-id <id>
  remove-label    --card-id <id> --label-id <id>
  add-label       --name <text> --color <color> [--board-id <id>]
  get-checklists  --card-id <id>
  get-comments    --card-id <id>
  add-comment     --card-id <id> --text <text>
  update-comment  --card-id <id> --comment-id <id> --text <text>

Environment variables (or .env file):
  TRELLO_API_KEY, TRELLO_TOKEN, TRELLO_BOARD_ID
EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  local command="${1:-}"
  shift || true

  case "$command" in
    get-card)       cmd_get_card "$@" ;;
    search-cards)   cmd_search_cards "$@" ;;
    get-lists)      cmd_get_lists "$@" ;;
    get-cards)      cmd_get_cards "$@" ;;
    move)           cmd_move "$@" ;;
    create-card)    cmd_create_card "$@" ;;
    update-card)    cmd_update_card "$@" ;;
    set-label)      cmd_set_label "$@" ;;
    remove-label)   cmd_remove_label "$@" ;;
    add-label)      cmd_add_label "$@" ;;
    get-checklists) cmd_get_checklists "$@" ;;
    get-comments)   cmd_get_comments "$@" ;;
    add-comment)    cmd_add_comment "$@" ;;
    update-comment) cmd_update_comment "$@" ;;
    help|--help|-h) usage ;;
    "")
      echo "ERROR: command required." >&2
      usage
      exit 1
      ;;
    *)
      echo "ERROR: unknown command '${command}'." >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
