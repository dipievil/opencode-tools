import { tool } from "@opencode-ai/plugin"
import { existsSync } from "node:fs"
import { dirname, join } from "node:path"

function detectProjectRoot(): string {
  let dir = process.cwd()

  while (dir !== "/") {
    if (existsSync(join(dir, ".opencode"))) {
      return dir
    }
    dir = dirname(dir)
  }

  throw new Error("No .opencode directory found in current path or parents")
}

const PROJECT_ROOT = detectProjectRoot()
const SCRIPT_PATH = `${PROJECT_ROOT}/.opencode/cronjobs/scripts/cron-tool.sh`

export default tool({
  description:
    "Manage opencode cron jobs — list, status, logs, tail, enable, disable, run",
  args: {
    command: tool.schema
      .string()
      .describe(
        "Operation: list, status, logs, tail, enable, disable, run",
      ),
    job: tool.schema
      .string()
      .optional()
      .describe(
        "Job name (required for tail, enable, disable, run; optional for status, logs)",
      ),
  },
  async execute(args) {
    const { command, job } = args
    const result = job
      ? await Bun.$`${SCRIPT_PATH} ${command} ${job}`.text()
      : await Bun.$`${SCRIPT_PATH} ${command}`.text()
    return result.trim()
  },
})
