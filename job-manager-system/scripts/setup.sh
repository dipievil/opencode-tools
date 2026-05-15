#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

VERSION="0.3.3"
CURRENT_VERSION="not-installed"

SOURCE_SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_AGENTS_DIR="$(cd "${SOURCE_SCRIPTS_DIR}/../agents" && pwd)"
SOURCE_TOOLS_DIR="$(cd "${SOURCE_SCRIPTS_DIR}/../tools" && pwd)"
SOURCE_JOBS_DIR="$(cd "${SOURCE_SCRIPTS_DIR}/../jobs" && pwd)"

ARG_PROJECT_DIR=""

# Project paths (detected)
PROJECT_ROOT=""
OPENCODE_DIR=""

# Opencode paths
OC_AGENTS_DIR=""
OC_TOOLS_DIR=""

FORCE_INSTALL=false

# Cron system paths (set after detecting project root)
SYSTEM_CONFIG_DIR=""
SYSTEM_STATEFILE_PATH=""
SYSTEM_SCRIPTS_DIR=""
SYSTEM_LOG_DIR=""
SYSTEM_VERSIONFILE_PATH=""
SYSTEM_JOBS_DIR=""



usage() {
  cat <<EOF
OpenCode Cron System Setup

Usage:
  setup.sh [--project-dir <path>]
  setup.sh [project-path]
  setup.sh --help

Options:
  --project-dir <path>  Install into the given project (must contain .opencode/)
  --help                Show this help message
  --force               Force install even if the same version is already installed
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

      SYSTEM_CONFIG_DIR="${OPENCODE_DIR}/cronjobs"
      SYSTEM_LOG_DIR="${SYSTEM_CONFIG_DIR}/logs"
      SYSTEM_SCRIPTS_DIR="${SYSTEM_CONFIG_DIR}/scripts"
      SYSTEM_STATEFILE_PATH="${SYSTEM_CONFIG_DIR}/.state.json"      
      SYSTEM_VERSIONFILE_PATH="${SYSTEM_CONFIG_DIR}/.version"
      SYSTEM_JOBS_DIR="${SYSTEM_CONFIG_DIR}/jobs"

      OC_AGENTS_DIR="${OPENCODE_DIR}/agents"
      OC_TOOLS_DIR="${OPENCODE_DIR}/tools"
      return 0
    fi
    dir="$(dirname "${dir}")"
  done

  echo "[ERROR] No .opencode directory found in current path or parents."
  echo "[ERROR] Run this setup from inside a project that already has .opencode/."
  exit 1
}

ensure_jq() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi

  echo "[INFO] jq not found. Installing jq..."

  if command -v apt-get >/dev/null 2>&1; then
    if [ "$(id -u)" -eq 0 ]; then
      apt-get update && apt-get install -y jq
    elif command -v sudo >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y jq
    else
      echo "[ERROR] jq is required but sudo is not available for installation."
      exit 1
    fi
  else
    echo "[ERROR] jq is required but apt-get was not found. Install jq manually and rerun setup."
    exit 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "[ERROR] jq installation failed."
    exit 1
  fi

  echo "[OK] jq installed successfully"
}

echo "=== OpenCode Cron System Setup ==="
parse_args "$@"
detect_project_root "${ARG_PROJECT_DIR}"
ensure_jq


if [ -f "${SYSTEM_VERSIONFILE_PATH}" ]; then
  CURRENT_VERSION="$(cat "${SYSTEM_VERSIONFILE_PATH}" | sed 's/version: //')"
  echo "[INFO] Current version is ${CURRENT_VERSION}"
  if [ "$(cat "${SYSTEM_VERSIONFILE_PATH}")" = "version: ${VERSION}" ]; then
    if [ "${FORCE_INSTALL}" = true ]; then
      echo "[WARN] Force install enabled. Reinstalling cron system even though it's already up to date."
    else
      echo "[SKIP] Cron system already set up (${CURRENT_VERSION})"
      exit 0
    fi
  fi
fi

echo "[INFO] Installing new version. New version: ${VERSION}"

mkdir -p "${SYSTEM_CONFIG_DIR}" "${SYSTEM_LOG_DIR}" "${SYSTEM_SCRIPTS_DIR}" "${OC_AGENTS_DIR}" "${OC_TOOLS_DIR}" "${SYSTEM_JOBS_DIR}"
[ -f "${SYSTEM_STATEFILE_PATH}" ] || echo '{}' > "${SYSTEM_STATEFILE_PATH}"
echo "[OK] Created ${SYSTEM_CONFIG_DIR}"

if [ -f "${SOURCE_AGENTS_DIR}/cron-manager.md" ]; then
  cp "${SOURCE_AGENTS_DIR}/cron-manager.md" "${OC_AGENTS_DIR}/cron-manager.md"
  echo "[OK] Installed opencode agent: cron-manager"
fi

echo "version: ${VERSION}" > "${SYSTEM_VERSIONFILE_PATH}"

if [ -f "${SOURCE_TOOLS_DIR}/cron-tool.ts" ]; then
  mkdir -p "${OC_TOOLS_DIR}"
  cp "${SOURCE_TOOLS_DIR}/cron-tool.ts" "${OC_TOOLS_DIR}/cron-tool.ts"
  echo "[OK] Installed opencode custom tool: cron-tool"
fi

cp "${SOURCE_SCRIPTS_DIR}/cron-tool.sh" "${SYSTEM_SCRIPTS_DIR}/cron-tool.sh"
cp "${SOURCE_SCRIPTS_DIR}/cron-runner.sh" "${SYSTEM_SCRIPTS_DIR}/cron-runner.sh"
chmod +x "${SYSTEM_SCRIPTS_DIR}/cron-tool.sh" "${SYSTEM_SCRIPTS_DIR}/cron-runner.sh"

# Create git ignore for logs and state
if [ ! -f "${SYSTEM_CONFIG_DIR}/.gitignore" ]; then
  echo -e "*.log\n.state.json" > "${SYSTEM_CONFIG_DIR}/.gitignore"
  echo "[OK] Created .gitignore for logs and state"
fi

"${SYSTEM_SCRIPTS_DIR}/cron-tool.sh" sync

cp "${SOURCE_JOBS_DIR}/job-template.md" "${SYSTEM_JOBS_DIR}/example-job.md"
echo "[OK] Created example job: example-job.md (disabled by default)"

cat <<EOF

=== Setup Complete ===

  Project root:    ${PROJECT_ROOT}
  OpenCode dir:    ${OPENCODE_DIR}
  Jobs directory:  ${SYSTEM_JOBS_DIR}
  Logs directory:  ${SYSTEM_LOG_DIR}
  Cron schedule:   configured from enabled job files
  Custom tool:     ${OC_TOOLS_DIR}/cron-tool.ts

Management (direct CLI):
  ${SYSTEM_SCRIPTS_DIR}/cron-tool.sh list       List all jobs
  ${SYSTEM_SCRIPTS_DIR}/cron-tool.sh status     Show job status
  ${SYSTEM_SCRIPTS_DIR}/cron-tool.sh logs       View job logs
  ${SYSTEM_SCRIPTS_DIR}/cron-tool.sh create     Create a new job
  ${SYSTEM_SCRIPTS_DIR}/cron-tool.sh enable <n> Enable a job
  ${SYSTEM_SCRIPTS_DIR}/cron-tool.sh disable <n> Disable a job

OpenCode Integration:
  Agent:    cron-manager (installed)
  Tool:     cron-tool (available as opencode custom tool)
  Use: opencode run --agent cron-manager "create a backup job"

EOF
