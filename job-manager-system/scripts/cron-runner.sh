#!/bin/bash

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
JOBS_DIR="${CONFIG_DIR}/jobs"
STATE_FILE="${CONFIG_DIR}/.state.json"
LOG_DIR="${CONFIG_DIR}/logs"
CRON_PREFIX="opencode-"
OPCODE_BIN="opencode"
DEFAULT_MODEL="opencode/big-pickle"
TARGET_JOB="${1:-}"
TARGET_BRANCH="${2:-}"
mkdir -p "${LOG_DIR}"
[ -f "${STATE_FILE}" ] || echo '{}' > "${STATE_FILE}"

# Cleanup old logs and temp files (older than 2 days)
find "${LOG_DIR}" -type f -name "*.log" -mtime +2 -exec rm -f {} + 2>/dev/null || true
find /tmp -type f -name "opencode-cron-*" -mtime +2 -exec rm -f {} + 2>/dev/null || true

schedule_to_cron() {
  case "$1" in
    hourly) echo "0 * * * *" ;;
    daily) echo "0 0 * * *" ;;
    *) echo "$1" ;;
  esac
}

for job_file in "${JOBS_DIR}"/*.md; do
  [ -f "${job_file}" ] || continue

  name=$(awk '/^name:/ {sub(/^name:[[:space:]]*/,""); gsub(/^["\x27]|["\x27]$/,""); print; exit}' "${job_file}")
  cron=$(awk '/^cron:/ {sub(/^cron:[[:space:]]*/,""); gsub(/^["\x27]|["\x27]$/,""); print; exit}' "${job_file}")
  schedule=$(awk '/^schedule:/ {sub(/^schedule:[[:space:]]*/,""); gsub(/^["\x27]|["\x27]$/,""); print; exit}' "${job_file}")
  enabled=$(awk '/^enabled:/ {sub(/^enabled:[[:space:]]*/,""); gsub(/^["\x27]|["\x27]$/,""); print; exit}' "${job_file}")
  project_folder=$(awk '/^project_folder:/ {sub(/^project_folder:[[:space:]]*/,""); gsub(/^["\x27]|["\x27]$/,""); print; exit}' "${job_file}")
  job_model=$(awk '/^model:/ {sub(/^model:[[:space:]]*/,""); gsub(/^["\x27]|["\x27]$/,""); print; exit}' "${job_file}")
  job_agent=$(awk '/^agent:/ {sub(/^agent:[[:space:]]*/,""); gsub(/^["\x27]|["\x27]$/,""); print; exit}' "${job_file}")
  job_branch=$(awk '/^branch:/ {sub(/^branch:[[:space:]]*/,""); gsub(/^["\x27]|["\x27]$/,""); print; exit}' "${job_file}")

  [ -n "${TARGET_BRANCH}" ] && job_branch="${TARGET_BRANCH}"

  [ -z "${name}" ] && name=$(basename "${job_file}" .md)
  [ -z "${project_folder}" ] && project_folder="${HOME}"
  case "${project_folder}" in
    "~") project_folder="${HOME}" ;;
    ~/*) project_folder="${HOME}/${project_folder#~/}" ;;
  esac
  cron_name="${CRON_PREFIX}${name}"

  [ "${enabled}" != "true" ] && continue
  [ -n "${TARGET_JOB}" ] && [ "${cron_name}" != "${TARGET_JOB}" ] && continue

  cron=$(schedule_to_cron "${cron}")
  [ -z "${cron}" ] && cron=$(schedule_to_cron "${schedule}")

  model="${job_model:-$DEFAULT_MODEL}"
  agent="${job_agent:-cron-manager}"

  log_file="${LOG_DIR}/${cron_name}-$(date +%Y%m%d-%H%M%S).log"

  prompt_file=$(mktemp /tmp/opencode-cron-XXXXXXXXXX)
  awk '
    BEGIN { delim=0 }
    /^---$/ { delim++; next }
    delim >= 2 { print }
  ' "${job_file}" > "${prompt_file}"

  commands_section=$(awk '
    /^## Commands/ { found=1; next }
    found && /^## / { exit }
    found && NF { print }
  ' "${prompt_file}")

  {
    echo "=== OpenCode Cron Job: ${name} ==="
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Cron: ${cron:-(not configured)}"
    echo "Schedule: ${schedule:-(not configured)}"
    echo "Model: ${model}"
    echo "Agent: ${agent}"
    echo "Project Folder: ${project_folder}"
    echo "---"

    if [ ! -d "${project_folder}" ]; then
      echo "[ERROR] Project folder not found: ${project_folder}"
      exit_code=1
      echo "---"
      echo "Finished: $(date '+%Y-%m-%d %H:%M:%S')"
      echo "Exit code: ${exit_code}"
      exit 0
    fi

    if [ -n "${commands_section}" ]; then
      echo "[Mode: Direct Command Execution]"
      echo ""
      script_file=$(mktemp /tmp/opencode-cron-script-XXXXXXXXXX)
      printf '%s\n' "${commands_section}" > "${script_file}"
      (
        cd "${project_folder}" || exit 1
        bash "${script_file}" 2>&1
      )
      exit_code=$?
      rm -f "${script_file}"
      echo ""
      echo "Exit code: ${exit_code}"
    else
      echo "[Mode: OpenCode AI Execution]"
      echo ""
      (
        cd "${project_folder}" || exit 1
        
        if [ -n "${job_branch}" ]; then
          base_branch="${job_branch}"
        else
          base_branch=$(git rev-parse --abbrev-ref HEAD)
        fi
        
        # Generate unique branch and worktree path
        timestamp=$(date +%Y%m%d%H%M%S)
        run_branch="cron/${name}-${timestamp}"
        worktree_path="/tmp/opencode-worktree-${name}-${timestamp}-$$"
        
        echo "Creating isolated worktree at ${worktree_path}"
        echo "Branch: ${run_branch} (from ${base_branch})"
        git pull origin "${base_branch}" || exit 1
        git worktree add -b "${run_branch}" "${worktree_path}" "${base_branch}" || exit 1
        
        cd "${worktree_path}" || exit 1
        
        ${OPCODE_BIN} run \
          --agent "${agent}" \
          --model "${model}" \
          --print-logs \
          --log-level ERROR \
          "$(cat "${prompt_file}")" 2>&1
        cmd_exit_code=$?
        
        # Cleanup worktree
        cd "${project_folder}" || exit 1
        git worktree remove --force "${worktree_path}" >/dev/null 2>&1 || true
        
        exit ${cmd_exit_code}
      )
      exit_code=$?
    fi

    echo "---"
    echo "Finished: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Exit code: ${exit_code}"
  } > "${log_file}" 2>&1

  rm -f "${prompt_file}"

  tmp=$(mktemp)
  jq --arg name "${cron_name}" \
     --arg now "$(date -Iseconds)" \
     --arg exit "${exit_code}" \
     '.[$name] = {last_run: $now, last_exit: ($exit | tonumber)}' \
     "${STATE_FILE}" > "${tmp}" && mv "${tmp}" "${STATE_FILE}"

done
