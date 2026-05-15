#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
JOBS_DIR="${CONFIG_DIR}/jobs"
STATE_FILE="${CONFIG_DIR}/.state.json"
LOG_DIR="${CONFIG_DIR}/logs"
CRON_PREFIX="opencode-"
CRON_RUNNER="${SCRIPT_DIR}/cron-runner.sh"
CRON_COMMENT="# OpenCode cron job:"

usage() {
  cat <<EOM
OpenCode Cron Tool — manage cron jobs and read logs

Usage:
  cron-tool.sh list                  List all jobs with status
  cron-tool.sh status [job]          Show last run status for all or one job
  cron-tool.sh logs [job]            Show recent log files for job(s)
  cron-tool.sh tail <job>            Tail the latest log for a job
  cron-tool.sh enable <job>          Enable a job
  cron-tool.sh disable <job>         Disable a job
  cron-tool.sh run <job>             Manually trigger a job now
  cron-tool.sh create                Create a new job interactively
  cron-tool.sh sync                  Sync system cron entries from job files
  cron-tool.sh help                  Show this help

EOM
  exit 0
}

get_job_field() {
  local field="$2"
  grep -E "^${field}:[[:space:]]*" "$1" | head -1 | sed -E "s/^${field}:[[:space:]]*//; s/^['\"]//; s/['\"]$//"
}

job_name() {
  local name
  name=$(get_job_field "$1" name)
  if [ -z "${name}" ]; then
    name=$(basename "$1" .md)
  fi
  echo "${name}"
}

job_enabled() {
  local enabled
  enabled=$(get_job_field "$1" enabled)
  echo "${enabled:-false}"
}

job_cron() {
  local cron
  cron=$(get_job_field "$1" cron)
  if [ -n "${cron}" ]; then
    echo "${cron}"
    return
  fi

  local schedule
  schedule=$(get_job_field "$1" schedule)
  case "${schedule}" in
    hourly) echo "0 * * * *" ;;
    daily) echo "0 0 * * *" ;;
    weekly) echo "0 0 * * 0" ;;
    *) echo "${schedule}" ;;
  esac
}

sync_crontab() {
  local temp_crontab
  temp_crontab=$(mktemp)
  if ! crontab -l 2>/dev/null > "${temp_crontab}"; then
    : > "${temp_crontab}"
  fi

  awk '!/^# OpenCode cron job:/ && !/cron-runner\.sh/' "${temp_crontab}" > "${temp_crontab}.clean"
  mv "${temp_crontab}.clean" "${temp_crontab}"

  for job_file in "${JOBS_DIR}"/*.md; do
    [ -f "${job_file}" ] || continue
    local enabled cron_expr name
    enabled=$(job_enabled "${job_file}")
    [ "${enabled}" != "true" ] && continue
    cron_expr=$(job_cron "${job_file}")
    [ -z "${cron_expr}" ] && continue
    name=$(job_name "${job_file}")
    printf '%s\n' "${CRON_COMMENT} ${name}" >> "${temp_crontab}"
    printf '%s %s\n' "${cron_expr}" "/bin/bash -lc 'export PATH=\"${HOME}/.opencode/bin:/usr/local/bin:/usr/bin:/bin\" && \"${CRON_RUNNER}\" \"${CRON_PREFIX}${name}\"'" >> "${temp_crontab}"
  done

  crontab "${temp_crontab}"
  rm -f "${temp_crontab}"
  echo "System cron entries synced from job files."
}

list_jobs() {
  echo "OpenCode Cron Jobs"
  printf "%-25s %-20s %-10s %s\n" "NAME" "CRON" "ENABLED" "LAST RUN"
  echo "-------------------------------------------------------------------------------"
  for job_file in "${JOBS_DIR}"/*.md; do
    [ -f "${job_file}" ] || continue
    local name cron enabled cron_name last_run last_run_short
    name=$(job_name "${job_file}")
    cron=$(job_cron "${job_file}")
    enabled=$(job_enabled "${job_file}")
    cron_name="${CRON_PREFIX}${name}"
    last_run=$(jq -r ".[\"${cron_name}\"].last_run // \"-\"" "${STATE_FILE}" 2>/dev/null)
    last_run_short="${last_run:0:19}"
    printf "%-25s %-20s %-10s %s\n" "${name}" "${cron}" "${enabled}" "${last_run_short}"
  done
}

show_status() {
  local filter="$1"
  for job_file in "${JOBS_DIR}"/*.md; do
    [ -f "${job_file}" ] || continue
    local name description cron enabled project_folder cron_name last_run last_exit
    name=$(job_name "${job_file}")
    [ -n "${filter}" ] && [ "${name}" != "${filter}" ] && continue
    description=$(get_job_field "${job_file}" description)
    cron=$(job_cron "${job_file}")
    enabled=$(job_enabled "${job_file}")
    project_folder=$(get_job_field "${job_file}" project_folder)
    [ -z "${project_folder}" ] && project_folder="${HOME}"
    cron_name="${CRON_PREFIX}${name}"
    last_run=$(jq -r ".[\"${cron_name}\"].last_run // \"never\"" "${STATE_FILE}" 2>/dev/null)
    last_exit=$(jq -r ".[\"${cron_name}\"].last_exit // \"-\"" "${STATE_FILE}" 2>/dev/null)

    echo "Job:           ${name}"
    echo "Description:   ${description}"
    echo "Project Folder: ${project_folder}"
    echo "Cron:          ${cron}"
    echo "Enabled:       ${enabled}"
    echo "Last Run:      ${last_run}"
    echo "Last Exit:     ${last_exit}"
    echo "File:          ${job_file}"
    echo "---"
  done
}

show_logs() {
  local filter="$1"
  if [ -n "${filter}" ]; then
    ls -1t "${LOG_DIR}"/*"${CRON_PREFIX}${filter}"*.log 2>/dev/null | head -10
  else
    ls -1t "${LOG_DIR}"/*"${CRON_PREFIX}"*.log 2>/dev/null | head -20
  fi
  [ $? -ne 0 ] && echo "No logs found."
}

tail_log() {
  local job="$1"
  local latest
  latest=$(ls -1t "${LOG_DIR}"/*"${CRON_PREFIX}${job}"*.log 2>/dev/null | head -1)
  if [ -z "${latest}" ]; then
    echo "No logs found for job: ${job}"
    exit 1
  fi
  less "${latest}"
}

toggle_job() {
  local job="$1"
  local state="$2"
  local job_file
  job_file=$(ls "${JOBS_DIR}"/*.md 2>/dev/null | while read -r f; do
    local name
    name=$(job_name "$f")
    [ "${name}" = "${job}" ] && echo "$f" && break
  done)

  if [ -z "${job_file}" ]; then
    echo "Job not found: ${job}"
    exit 1
  fi

  if grep -q "^enabled:" "${job_file}"; then
    sed -i "s/^enabled:.*/enabled: ${state}/" "${job_file}"
  else
    sed -i "0,/^---$/{s/^---$/---\nenabled: ${state}/}" "${job_file}"
  fi
  echo "Job '${job}' ${state}d."
  sync_crontab
}

run_job() {
  local job="$1"
  shift
  local branch=""
  if [ "$1" = "--branch" ]; then
    branch="$2"
  fi
  local job_file
  job_file=$(ls "${JOBS_DIR}"/*.md 2>/dev/null | while read -r f; do
    local name
    name=$(job_name "$f")
    [ "${name}" = "${job}" ] && echo "$f" && break
  done)

  if [ -z "${job_file}" ]; then
    echo "Job not found: ${job}"
    exit 1
  fi

  echo "Running job '${job}'..."
  "${CRON_RUNNER}" "${CRON_PREFIX}${job}" "${branch}"
}

create_job() {
  echo "Creating a new OpenCode cron job..."
  read -r -p "Job name (no spaces): " name
  read -r -p "Description: " description
  read -r -p "Project folder [${HOME}]: " project_folder
  project_folder="${project_folder:-${HOME}}"
  echo "Schedule options: hourly, daily, weekly, or custom cron"
  read -r -p "Schedule [hourly]: " schedule
  schedule="${schedule:-hourly}"

  job_file="${JOBS_DIR}/${name}.md"
  if [ -f "${job_file}" ]; then
    echo "Job already exists: ${job_file}"
    exit 1
  fi

  awk -v name="${name}" -v desc="${description}" -v project_folder="${project_folder}" -v schedule="${schedule}" '
    /^name:[[:space:]]/ { print "name: " name; next }
    /^description:[[:space:]]/ { print "description: " desc; next }
    /^project_folder:[[:space:]]/ { print "project_folder: " project_folder; next }
    /^schedule:[[:space:]]/ { print "schedule: " schedule; next }
    { print }
  ' "${0%/*}/job-template.md" > "${job_file}"

  echo "Job created: ${job_file}"
  echo "Edit the file to add custom instructions, then enable it with:"
  echo "  cron-tool.sh enable ${name}"
}

case "${1:-help}" in
  list)    list_jobs ;;
  status)  show_status "$2" ;;
  logs)    show_logs "$2" ;;
  tail)    shift; tail_log "$1" ;;
  enable)  shift; toggle_job "$1" "true" ;;
  disable) shift; toggle_job "$1" "false" ;;
  run)
    shift
    local job="$1"
    shift
    run_job "${job}" "$@"
    ;;
  create)  create_job ;;
  sync)    sync_crontab ;;
  help|*)  usage ;;
esac
