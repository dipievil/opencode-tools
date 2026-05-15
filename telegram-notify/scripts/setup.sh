#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Global paths and constants.
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="$(cd "${SCRIPTS_DIR}/../tools" && pwd)"

OC_TOOLS_DIR="${HOME}/.config/opencode/tools"
CONFIG_DIR="${HOME}/.config/opencode/telegram-notify"
VERSION="0.1.0"
VERSION_FILE="${CONFIG_DIR}/.version"

SOURCE_TOOL_TS="${TOOLS_DIR}/telegram-notify.ts"
SOURCE_SCRIPT_SH="${SCRIPTS_DIR}/telegram-notify.sh"
TARGET_TOOL_TS="${OC_TOOLS_DIR}/telegram-notify.ts"
TARGET_SCRIPT_SH="${CONFIG_DIR}/telegram-notify.sh"
TARGET_ENV_FILE="${CONFIG_DIR}/.env"

usage() {
  cat <<EOF
OpenCode Telegram Session Notification Setup

Usage:
  setup.sh         Install or update telegram notification tool
  setup.sh --help  Show this help
EOF
}

main() {
  if [[ "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ $# -gt 0 ]]; then
    echo "[ERROR] Invalid argument: $1"
    usage
    exit 1
  fi

  echo "=== OpenCode Telegram Notification Setup ==="

  mkdir -p "${OC_TOOLS_DIR}" "${CONFIG_DIR}"

  if [[ -f "${VERSION_FILE}" ]]; then
    current_version="$(sed -n 's/^version:[[:space:]]*//p' "${VERSION_FILE}")"
    if [[ "${current_version}" == "${VERSION}" ]]; then
      echo "[SKIP] Telegram tool already set up (version: ${VERSION})"
      exit 0
    fi
    echo "[INFO] Updating telegram tool from ${current_version:-unknown} to ${VERSION}"
  else
    echo "[INFO] Fresh install (version: ${VERSION})"
  fi

  if [[ ! -f "${SOURCE_TOOL_TS}" ]]; then
    echo "[ERROR] Source file not found: ${SOURCE_TOOL_TS}"
    exit 1
  fi

  if [[ ! -f "${SOURCE_SCRIPT_SH}" ]]; then
    echo "[ERROR] Source file not found: ${SOURCE_SCRIPT_SH}"
    exit 1
  fi

  cp "${SOURCE_TOOL_TS}" "${TARGET_TOOL_TS}"
  echo "[OK] Installed opencode custom tool: telegram-notify.ts"

  cp "${SOURCE_SCRIPT_SH}" "${TARGET_SCRIPT_SH}"
  chmod +x "${TARGET_SCRIPT_SH}"
  echo "[OK] Installed runtime script: telegram-notify.sh"

  if [[ ! -f "${TARGET_ENV_FILE}" ]]; then
    cat > "${TARGET_ENV_FILE}" <<EOF
TELEGRAM-TOKEN=
TELEGRAM-CHAT-ID=
EOF
    chmod 600 "${TARGET_ENV_FILE}"
    echo "[OK] Created ${TARGET_ENV_FILE} template"
  else
    echo "[SKIP] Existing ${TARGET_ENV_FILE} preserved"
  fi

  echo "version: ${VERSION}" > "${VERSION_FILE}"

  cat <<EOF

=== Setup Complete ===

  Tool file:       ${TARGET_TOOL_TS}
  Runtime script:  ${TARGET_SCRIPT_SH}
  Credentials file:${TARGET_ENV_FILE}

Next steps:
  1. Fill ${TARGET_ENV_FILE} with TELEGRAM-TOKEN and TELEGRAM-CHAT-ID
  2. Use in OpenCode via custom tool: telegram-tool

EOF
}

main "$@"
