# OpenCode Cron System

Automated job scheduling system using opencode and system cron. Each job is a markdown file — define instructions for AI execution or shell commands, and system cron triggers each job on the configured cron expression.

## Architecture

```plaintext
system cron (per job)
  └─ cron-runner.sh <job>
    ├─ Reads .opencode/cronjobs/*.md
       ├─ Parses YAML frontmatter (name, cron, enabled)
       ├─ Extracts instructions or shell commands from body
       ├─ Runs via opencode (AI) or eval (shell)
    └─ Logs output to .opencode/cronjobs/logs/

Management CLI:
  cron-tool.sh list|status|logs|enable|disable|run|create

OpenCode Agent:
  opencode run --agent cron-manager "create a backup job"
```

## Setup

```bash
./docker/opencode/job-manager-system/scripts/setup.sh
```

This will:

1. Validate that the current project has `.opencode/`
2. Create `.opencode/cronjobs/` with logs/ and state file
3. Install the `cron-manager` agent and `cron-tool` as project-local files in `.opencode/`
4. Sync system cron entries from enabled job files
5. Create an example job (disabled by default)

## Job File Format

Each job is a markdown file in `.opencode/cronjobs/`:

```markdown
---
name: health-check
description: Run system health check
project_folder: ~/repos/my-project
schedule: hourly
enabled: false
tags: [monitoring]
model: opencode/big-pickle
agent: cron-manager
---

## Description
Check system health and report issues.

## Instructions
Run a comprehensive system health check...

## Commands
#!/bin/bash
df -h
free -h
```

- **Frontmatter**: name, project_folder, schedule (hourly/daily/weekly or custom), enabled (true/false), model, agent
- **## Instructions**: Prompt sent to `opencode run` for AI execution
- **## Commands**: Shell commands executed directly (avoids AI cost). Takes priority over Instructions.

## Tools

### cron-tool.sh

```bash
.opencode/cronjobs/scripts/cron-tool.sh list       # List all jobs
.opencode/cronjobs/scripts/cron-tool.sh status     # Show detailed status
.opencode/cronjobs/scripts/cron-tool.sh logs       # Show recent logs
.opencode/cronjobs/scripts/cron-tool.sh tail <job> # Latest log for a job
.opencode/cronjobs/scripts/cron-tool.sh enable <n> # Enable a job
.opencode/cronjobs/scripts/cron-tool.sh disable <n># Disable a job
.opencode/cronjobs/scripts/cron-tool.sh run <job>  # Trigger now
.opencode/cronjobs/scripts/cron-tool.sh create     # Create a new job
```

Notes:

- Manual `run` bypasses system cron and executes the selected job immediately.
- `run` returns success/failure and prints the generated log file path.
- `logs` now returns `No logs found.` without failing the command.
- `tail` uses `tail -n 200` in non-interactive environments.

### OpenCode Agent

```bash
opencode run --agent cron-manager "list my jobs"
opencode run --agent cron-manager "create a daily backup job"
opencode run --agent cron-manager "show logs for health-check"
```

## Logs

Logs are stored at `.opencode/cronjobs/logs/{job-name}-{timestamp}.log`.
Each log contains start time, execution mode, output, exit code, and finish time.

## State Tracking

`.opencode/cronjobs/.state.json` tracks `last_run` and `last_exit` for each job, enabling daily-schedule jobs to skip runs when already executed today.

## Failure Notifications

When a job fails (`exit_code != 0`), the runner can send a best-effort notification:

1. If `OPENCODE_CRON_FAILURE_HOOK` is set, it executes that shell command.
2. Otherwise, if `.opencode/tools/telegram-tool.sh` exists and is executable, it sends a Telegram message.

Hook environment variables:

- `OPENCODE_CRON_JOB_NAME`
- `OPENCODE_CRON_EXIT_CODE`
- `OPENCODE_CRON_LOG_FILE`
- `OPENCODE_CRON_MESSAGE`

## Example: Create a Job

```bash
# Interactive
.opencode/cronjobs/scripts/cron-tool.sh create
.opencode/cronjobs/scripts/cron-tool.sh enable my-job

# Or manually
cp job-template.md .opencode/cronjobs/my-task.md
# Edit the file, then:
.opencode/cronjobs/scripts/cron-tool.sh enable my-task
.opencode/cronjobs/scripts/cron-tool.sh run my-task  # Test it
```

## Version control

This system version is set on `.version` by the installer script. Future updates can check this file to determine if an update is needed or if the system is already up to date.