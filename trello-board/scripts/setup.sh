#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

VERSION="0.1.5"
CURRENT_VERSION="not-installed"

SOURCE_SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_SKILL_DIR="$(cd "${SOURCE_SCRIPTS_DIR}/../skill/trello-board" && pwd)"
SOURCE_TOOLS_DIR="$(cd "${SOURCE_SCRIPTS_DIR}/../tools" && pwd)"

ARG_PROJECT_DIR=""

# Project paths (detected)
PROJECT_ROOT=""
OPENCODE_DIR=""

# Opencode paths
OC_SKILLS_DIR=""
OC_TOOLS_DIR=""

FORCE_INSTALL=false

# Trello skill paths (set after detecting project root)
SYSTEM_SKILL_DIR=""
SYSTEM_VERSIONFILE_PATH=""
SYSTEM_SCRIPTS_DIR=""

usage() {
  cat <<EOF
OpenCode Trello Board Setup

Usage:
  setup.sh [--project-dir <path>]
  setup.sh [project-path]
  setup.sh --help

Options:
  --project-dir <path>  Install into the given project (must contain .opencode/)
  --force               Force install even if the same version is already installed
  --help                Show this help message
EOF
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --force)
        FORCE_INSTALL=true
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      --project-dir)
        if [ -z "${2:-}" ]; then
          echo "[ERROR] Missing value for --project-dir"
          usage
          exit 1
        fi
        ARG_PROJECT_DIR="$2"
        shift 2
        ;;
      *)
        if [ -z "${ARG_PROJECT_DIR}" ]; then
          ARG_PROJECT_DIR="$1"
          shift
        else
          echo "[ERROR] Unexpected argument: $1"
          usage
          exit 1
        fi
        ;;
    esac
  done
}

detect_project_root() {
  local dir

  if [ -n "${1:-}" ]; then
    if [ ! -d "$1" ]; then
      echo "[ERROR] Project directory does not exist: $1"
      exit 1
    fi
    dir="$(cd "$1" && pwd)"
  else
    dir="$(pwd)"
  fi

  while [ "${dir}" != "/" ]; do
    if [ -d "${dir}/.opencode" ]; then
      PROJECT_ROOT="${dir}"
      OPENCODE_DIR="${PROJECT_ROOT}/.opencode"

      SYSTEM_SKILL_DIR="${OPENCODE_DIR}/skills/trello-board"
      SYSTEM_SCRIPTS_DIR="${SYSTEM_SKILL_DIR}/scripts"
      SYSTEM_VERSIONFILE_PATH="${SYSTEM_SKILL_DIR}/.version"
      SYSTEM_ENV_FILE="${SYSTEM_SCRIPTS_DIR}/.env"

      OC_SKILLS_DIR="${OPENCODE_DIR}/skills"
      OC_TOOLS_DIR="${OPENCODE_DIR}/tools"
      return 0
    fi
    dir="$(dirname "${dir}")"
  done

  echo "[ERROR] No .opencode directory found in current path or parents."
  echo "[ERROR] Run this setup from inside a project that already has .opencode/."
  exit 1
}

echo "=== OpenCode Trello Board Setup ==="
parse_args "$@"
detect_project_root "${ARG_PROJECT_DIR}"

if [ -f "${SYSTEM_VERSIONFILE_PATH}" ]; then
  CURRENT_VERSION="$(cat "${SYSTEM_VERSIONFILE_PATH}" | sed 's/version: //')"
  echo "[INFO] Current version is ${CURRENT_VERSION}"
  if [ "$(cat "${SYSTEM_VERSIONFILE_PATH}")" = "version: ${VERSION}" ]; then
    if [ "${FORCE_INSTALL}" = true ]; then
      echo "[WARN] Force install enabled. Reinstalling trello-board even though it's already up to date."
    else
      echo "[SKIP] Trello board already set up (${CURRENT_VERSION})"
      exit 0
    fi
  fi
fi

echo "[INFO] Installing new version. New version: ${VERSION}"

mkdir -p "${SYSTEM_SKILL_DIR}" "${SYSTEM_SCRIPTS_DIR}" "${OC_TOOLS_DIR}"
echo "[OK] Created ${SYSTEM_SKILL_DIR}"

if [ -f "${SOURCE_SKILL_DIR}/SKILL.md" ]; then
  cp "${SOURCE_SKILL_DIR}/SKILL.md" "${SYSTEM_SKILL_DIR}/SKILL.md"
  echo "[OK] Installed skill: trello-board (SKILL.md)"
fi

if [ -f "${SOURCE_SCRIPTS_DIR}/trello-call.sh" ]; then
  cp "${SOURCE_SCRIPTS_DIR}/trello-call.sh" "${SYSTEM_SCRIPTS_DIR}/trello-call.sh"
  chmod +x "${SYSTEM_SCRIPTS_DIR}/trello-call.sh"
  echo "[OK] Installed script: trello-call.sh"
fi

if [ -f "${SOURCE_TOOLS_DIR}/trello-board-tool.ts" ]; then
  cp "${SOURCE_TOOLS_DIR}/trello-board-tool.ts" "${OC_TOOLS_DIR}/trello-board-tool.ts"
  echo "[OK] Installed opencode custom tool: trello-board-tool"
fi

# Create or update .env file with script path and credential placeholders
TRELLO_CALL_SCRIPT_PATH="${SYSTEM_SCRIPTS_DIR}/trello-call.sh"
if [ ! -f "${SYSTEM_ENV_FILE}" ]; then
  {
    echo "TRELLO_API_KEY=your_trello_api_key_here"
    echo "TRELLO_TOKEN=your_trello_token_here"
    echo "TRELLO_BOARD_ID=your_trello_board_id_here"
    echo "TRELLO_CALL_SCRIPT_PATH=${TRELLO_CALL_SCRIPT_PATH}"
  } > "${SYSTEM_ENV_FILE}"
  echo "[OK] Created environment file: ${SYSTEM_ENV_FILE}"
  echo "[WARN] Please update ${SYSTEM_ENV_FILE} with your Trello API key, token, and board ID before using the tool."
else
  # Always refresh TRELLO_CALL_SCRIPT_PATH in case the project moved
  if grep -q '^TRELLO_CALL_SCRIPT_PATH=' "${SYSTEM_ENV_FILE}"; then
    sed -i "s|^TRELLO_CALL_SCRIPT_PATH=.*|TRELLO_CALL_SCRIPT_PATH=${TRELLO_CALL_SCRIPT_PATH}|"\ "${SYSTEM_ENV_FILE}"
  else
    sed -i "1s|^|TRELLO_CALL_SCRIPT_PATH=${TRELLO_CALL_SCRIPT_PATH}\n|" "${SYSTEM_ENV_FILE}"
  fi
  echo "[OK] Updated TRELLO_CALL_SCRIPT_PATH in ${SYSTEM_ENV_FILE}"
fi

echo "version: ${VERSION}" > "${SYSTEM_VERSIONFILE_PATH}"
echo "[OK] Version file written: ${VERSION}"

cat <<EOF

=== Setup Complete ===

  Project root:    ${PROJECT_ROOT}
  OpenCode dir:    ${OPENCODE_DIR}
  Skill directory: ${SYSTEM_SKILL_DIR}
  Scripts:         ${SYSTEM_SCRIPTS_DIR}/trello-call.sh
  Custom tool:     ${OC_TOOLS_DIR}/trello-board-tool.ts

Environment:
  Set TRELLO_API_KEY and TRELLO_TOKEN in your project's .env file
  or export them in your shell before using the tool.

OpenCode Integration:
  Skill:  trello-board (installed at .opencode/skills/trello-board/)
  Tool:   trello-board-tool (available as opencode custom tool)
  Use: opencode run "list my Trello boards"

EOF
