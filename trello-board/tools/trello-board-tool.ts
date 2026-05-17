import { tool } from "@opencode-ai/plugin"
import { env } from "bun"
import { existsSync } from "node:fs"
import { dirname, join } from "node:path"

interface TrelloLabel {
  id: string
  name: string
  color: string
}

interface TrelloCover {
  id: string
  color: string
  size: string
  brightness: string
}

interface TrelloBadges {
  attachmentsByType: {
    trello: {
      card: number
    }
  }
  start: string
  dueComplete: boolean
}

interface TrelloCard {
  id: string
  address: string
  badges: TrelloBadges
  checkItemStates: string[]
  closed: boolean
  creationMethod: string
  desc: string
  descData: { emoji: Record<string, unknown> }
  due: string
  idBoard: string
  idChecklists: Array<{ id: string }>
  idLabels: TrelloLabel[]
  idList: string
  idMembers: string[]
  idShort: number
  labels: string[]
  name: string
  shortLink: string
  shortUrl: string
  url: string
  cover: TrelloCover
}

const PROJECT_ROOT = detectProjectRoot()
const SCRIPT_PATH = `${PROJECT_ROOT}/.opencode/skills/trello-board/scripts/trello-call.sh`

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

async function run(args: string[]): Promise<string> {

  const result = await Bun.$`${SCRIPT_PATH}" ${args.map(a => `"${a.replace(/"/g, '\\"')}"`).join(" ")}`.env(env).text()

  return result.trim()
}

export const getCard = tool({
  description: "Get a Trello card details by its ID",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to retrieve"),
  },
  async execute(args) {
    return run(["get-card", "--card-id", args.cardId])
  },
})

export const searchCards = tool({
  description: "Search for Trello cards by name",
  args: {
    query: tool.schema.string().describe("Search query to find matching Trello cards"),
  },
  async execute(args) {
    return run(["search-cards", "--query", args.query])
  },
})

export const getLists = tool({
  description: "Get trello lists with names and IDs",
  args: {},
  async execute() {
    return run(["get-lists"])
  },
})

export const move = tool({
  description: "Move a trello card to another list",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to move"),
    listId: tool.schema.string().describe("ID of the Trello list to move the card to"),
  },
  async execute(args) {
    return run(["move", "--card-id", args.cardId, "--list-id", args.listId])
  },
})

export const createCard = tool({
  description: "Create a new card in a Trello list",
  args: {
    name: tool.schema.string().describe("Name of the new card"),
    desc: tool.schema.string().describe("Description of the new card"),
    listId: tool.schema.string().describe("ID of the Trello list to create the card in"),
  },
  async execute(args) {
    return run(["create-card", "--name", args.name, "--desc", args.desc, "--list-id", args.listId])
  },
})

export const updateCard = tool({
  description: "Update a Trello card's name and description",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to update"),
    name: tool.schema.string().describe("New name for the card"),
    desc: tool.schema.string().describe("New description for the card"),
  },
  async execute(args) {
    return run(["update-card", "--card-id", args.cardId, "--name", args.name, "--desc", args.desc])
  },
})

export const setLabel = tool({
  description: "Set a label on a Trello card",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to label"),
    labelId: tool.schema.string().describe("ID of the label to set on the card"),
  },
  async execute(args) {
    return run(["set-label", "--card-id", args.cardId, "--label-id", args.labelId])
  },
})

export const removeLabel = tool({
  description: "Remove a label from a Trello card",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to remove label from"),
    labelId: tool.schema.string().describe("ID of the label to remove from the card"),
  },
  async execute(args) {
    return run(["remove-label", "--card-id", args.cardId, "--label-id", args.labelId])
  },
})

export const createLabel = tool({
  description: "Create a new label",
  args: {
    name: tool.schema.string().describe("Name of the new label"),
    color: tool.schema.string().describe("Color of the new label"),
  },
  async execute(args) {
    return run(["add-label", "--name", args.name, "--color", args.color])
  },
})

export const list = tool({
  description: "List all cards in a Trello list",
  args: {
    listId: tool.schema.string().describe("ID of the Trello list to list cards from"),
  },
  async execute(args) {
    return run(["get-cards", "--list-id", args.listId])
  },
})

export const checklists = tool({
  description: "Get checklists of a Trello card",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to get checklists from"),
  },
  async execute(args) {
    return run(["get-checklists", "--card-id", args.cardId])
  },
})

export const comments = tool({
  description: "Get comments of a Trello card",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to get comments from"),
  },
  async execute(args) {
    return run(["get-comments", "--card-id", args.cardId])
  },
})

export const addComment = tool({
  description: "Add a comment to a Trello card",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to add a comment to"),
    text: tool.schema.string().describe("Text of the comment to add"),
  },
  async execute(args) {
    return run(["add-comment", "--card-id", args.cardId, "--text", args.text])
  },
})

export const updateComment = tool({
  description: "Update a comment on a Trello card",
  args: {
    commentId: tool.schema.string().describe("ID of the comment to update"),
    cardId: tool.schema.string().describe("ID of the Trello card containing the comment"),
    text: tool.schema.string().describe("New text of the comment"),
  },
  async execute(args) {
    return run(["update-comment", "--comment-id", args.commentId, "--card-id", args.cardId, "--text", args.text])
  },
})

interface TrelloCover {
  idAttachment: string
  color: string
  idUploadedBackground: string
  size: string
  brightness: string
}
