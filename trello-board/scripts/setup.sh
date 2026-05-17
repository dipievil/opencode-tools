#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

VERSION="0.1.11"
CURRENT_VERSION="not-installed"

SOURCE_SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_SKILL_DIR="$(cd "${SOURCE_SCRIPTS_DIR}/../skill/trello-board" && pwd)"

ARG_PROJECT_DIR=""

# Project paths (detected)
PROJECT_ROOT=""
OPENCODE_DIR=""

# Opencode paths
OC_SKILLS_DIR=""

FORCE_INSTALL=false

# Trello skill paths (set after detecting project root)
SYSTEM_SKILL_DIR=""
SYSTEM_VERSIONFILE_PATH=""

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
      SYSTEM_VERSIONFILE_PATH="${SYSTEM_SKILL_DIR}/.version"

      OC_SKILLS_DIR="${OPENCODE_DIR}/skills"
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

mkdir -p "${SYSTEM_SKILL_DIR}"
echo "[OK] Created ${SYSTEM_SKILL_DIR}"

if [ -f "${SOURCE_SKILL_DIR}/SKILL.md" ]; then
  cp "${SOURCE_SKILL_DIR}/SKILL.md" "${SYSTEM_SKILL_DIR}/SKILL.md"
  echo "[OK] Installed skill: trello-board (SKILL.md)"
fi

echo "version: ${VERSION}" > "${SYSTEM_VERSIONFILE_PATH}"
echo "[OK] Version file written: ${VERSION}"

cat <<EOF

=== Setup Complete ===

  Project root:    ${PROJECT_ROOT}
  Skill directory: ${SYSTEM_SKILL_DIR}

The skill uses Trello MCP tools — make sure the Trello MCP server is configured in your opencode.json.

EOF
