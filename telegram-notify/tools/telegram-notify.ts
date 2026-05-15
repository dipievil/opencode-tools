import { tool } from "@opencode-ai/plugin"

const HOME = process.env.HOME ?? ""
const SCRIPT_PATH = `${HOME}/.config/opencode/telegram-notify/telegram-notify.sh`

export default tool({
    description:
        "Send a notification to a Telegram user via bot.",
    args: {
        message: tool.schema
            .string()
            .describe(
                "Message to be sent to the user",
            ),
    },
    async execute(args: { message: string }) {
        const { message } = args
        const result = await Bun.$`${SCRIPT_PATH} ${message}`.text()
        return result.trim()
    },
})
