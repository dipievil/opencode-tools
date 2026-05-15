#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# telegram-notify.sh
# Sends a Telegram message using a bot token stored in a .env file.
#
# Usage:
#   ./telegram-notify.sh "<message>"
#
# Environment variables (loaded from .env in the same directory):
#   TELEGRAM-TOKEN    — Telegram Bot API token
#   TELEGRAM-CHAT-ID  — Target chat/group/channel ID
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# --- Validate arguments ---
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"<message>\"" >&2
  exit 1
fi

MESSAGE="$1"

# --- Load .env ---
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Error: .env file not found at ${ENV_FILE}" >&2
  exit 1
fi

# Parse .env manually — bash does not support hyphens in variable names,
# so `source` would fail trying to interpret TELEGRAM-TOKEN as a command.
get_env_value() {
  local key="$1"
  grep -m1 "^${key}=" "${ENV_FILE}" | cut -d'=' -f2-
}

BOT_TOKEN="$(get_env_value 'TELEGRAM-TOKEN')"
CHAT_ID="$(get_env_value 'TELEGRAM-CHAT-ID')"

if [[ -z "${BOT_TOKEN}" ]]; then
  echo "Error: TELEGRAM-TOKEN is not set or empty in ${ENV_FILE}" >&2
  exit 1
fi

if [[ -z "${CHAT_ID}" ]]; then
  echo "Error: TELEGRAM-CHAT-ID is not set or empty in ${ENV_FILE}" >&2
  exit 1
fi

# --- Send message via Telegram Bot API ---
TELEGRAM_API_URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

response=$(curl --silent --show-error \
  --request POST "${TELEGRAM_API_URL}" \
  --data-urlencode "chat_id=${CHAT_ID}" \
  --data-urlencode "text=${MESSAGE}" \
  --data-urlencode "parse_mode=HTML")

echo "${response}"
