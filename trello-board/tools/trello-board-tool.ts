import { tool } from "@opencode-ai/plugin"
import { existsSync, readFileSync } from "node:fs"
import { dirname, join } from "node:path"

function detectProjectRoot(): string | null {
  let dir = process.cwd()
  while (dir !== "/") {
    if (existsSync(join(dir, ".opencode"))) {
      return dir
    }
    dir = dirname(dir)
  }
  return null
}

function loadEnvFile(): void {
  const root = detectProjectRoot()
  if (!root) return
  const envPath = join(root, ".opencode", "skills", "trello-board", ".env")
  if (!existsSync(envPath)) return
  const content = readFileSync(envPath, "utf-8")
  for (const line of content.split("\n")) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith("#")) continue
    const eqIdx = trimmed.indexOf("=")
    if (eqIdx === -1) continue
    const key = trimmed.slice(0, eqIdx).trim()
    const value = trimmed.slice(eqIdx + 1).trim()
    if (key && !process.env[key]) {
      process.env[key] = value
    }
  }
}

loadEnvFile()

function requireCredentials() {
  const apiKey = process.env.TRELLO_API_KEY
  const token = process.env.TRELLO_TOKEN
  if (!apiKey || !token) {
    throw new Error("TRELLO_API_KEY and TRELLO_TOKEN must be set")
  }
  return { apiKey, token }
}

function authParams(): string {
  const { apiKey, token } = requireCredentials()
  return `key=${encodeURIComponent(apiKey)}&token=${encodeURIComponent(token)}`
}

async function apiGet<T>(path: string, extraParams = ""): Promise<T> {
  const url = `https://api.trello.com/1${path}?${authParams()}${extraParams ? `&${extraParams}` : ""}`
  const res = await fetch(url)
  if (!res.ok) throw new Error(`Trello API error ${res.status}: ${await res.text()}`)
  return res.json()
}

async function apiPost<T>(path: string, data: Record<string, unknown>): Promise<T> {
  const url = `https://api.trello.com/1${path}?${authParams()}`
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  })
  if (!res.ok) throw new Error(`Trello API error ${res.status}: ${await res.text()}`)
  return res.json()
}

async function apiPut<T>(path: string, data: Record<string, unknown>): Promise<T> {
  const url = `https://api.trello.com/1${path}?${authParams()}`
  const res = await fetch(url, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  })
  if (!res.ok) throw new Error(`Trello API error ${res.status}: ${await res.text()}`)
  return res.json()
}

async function apiDelete(path: string): Promise<void> {
  const url = `https://api.trello.com/1${path}?${authParams()}`
  const res = await fetch(url, { method: "DELETE" })
  if (!res.ok) throw new Error(`Trello API error ${res.status}: ${await res.text()}`)
}

function boardId(): string {
  return process.env.TRELLO_BOARD_ID || ""
}

export const getCard = tool({
  description: "Get a Trello card details by its ID",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to retrieve"),
  },
  async execute(args) {
    const card = await apiGet<Record<string, unknown>>(`/cards/${args.cardId}`)
    const fields = ["id", "name", "desc", "due", "url", "idList", "idBoard", "idLabels", "idChecklists", "shortUrl"]
    const filtered: Record<string, unknown> = {}
    for (const f of fields) filtered[f] = card[f]
    return JSON.stringify(filtered)
  },
})

export const searchCards = tool({
  description: "Search for Trello cards by name",
  args: {
    query: tool.schema.string().describe("Search query to find matching Trello cards"),
  },
  async execute(args) {
    const encoded = encodeURIComponent(args.query)
    const boardParam = process.env.TRELLO_BOARD_ID ? `&idBoards=${process.env.TRELLO_BOARD_ID}` : ""
    const result = await apiGet<{ cards: Record<string, unknown>[] }>(
      "/search",
      `query=${encoded}&modelTypes=cards${boardParam}`,
    )
    return JSON.stringify(
      result.cards.map((c) => ({
        id: c.id,
        name: c.name,
        desc: c.desc,
        idList: c.idList,
        url: c.url,
        shortUrl: c.shortUrl,
      })),
    )
  },
})

export const getLists = tool({
  description: "Get trello lists with names and IDs",
  args: {},
  async execute() {
    const bid = boardId()
    if (!bid) throw new Error("TRELLO_BOARD_ID must be set")
    const lists = await apiGet<Record<string, unknown>[]>(`/boards/${bid}/lists?fields=id,name`)
    return JSON.stringify(lists.map((l) => ({ id: l.id, name: l.name })))
  },
})

export const move = tool({
  description: "Move a trello card to another list",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to move"),
    listId: tool.schema.string().describe("ID of the Trello list to move the card to"),
  },
  async execute(args) {
    const card = await apiPut<Record<string, unknown>>(`/cards/${args.cardId}`, { idList: args.listId })
    return JSON.stringify({ id: card.id, name: card.name, idList: card.idList, url: card.url })
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
    const card = await apiPost<Record<string, unknown>>("/cards", {
      name: args.name,
      desc: args.desc,
      idList: args.listId,
    })
    return JSON.stringify({ id: card.id, name: card.name, url: card.url })
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
    const payload: Record<string, unknown> = {}
    if (args.name) payload.name = args.name
    if (args.desc) payload.desc = args.desc
    const card = await apiPut<Record<string, unknown>>(`/cards/${args.cardId}`, payload)
    return JSON.stringify({ id: card.id, name: card.name, desc: card.desc, url: card.url })
  },
})

export const setLabel = tool({
  description: "Set a label on a Trello card",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to label"),
    labelId: tool.schema.string().describe("ID of the label to set on the card"),
  },
  async execute(args) {
    return JSON.stringify(await apiPost<Record<string, unknown>>(`/cards/${args.cardId}/idLabels`, { value: args.labelId }))
  },
})

export const removeLabel = tool({
  description: "Remove a label from a Trello card",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to remove label from"),
    labelId: tool.schema.string().describe("ID of the label to remove from the card"),
  },
  async execute(args) {
    await apiDelete(`/cards/${args.cardId}/idLabels/${args.labelId}`)
    return JSON.stringify({ removed: args.labelId })
  },
})

export const createLabel = tool({
  description: "Create a new label",
  args: {
    name: tool.schema.string().describe("Name of the new label"),
    color: tool.schema.string().describe("Color of the new label"),
  },
  async execute(args) {
    const bid = boardId()
    if (!bid) throw new Error("TRELLO_BOARD_ID must be set")
    const label = await apiPost<Record<string, unknown>>("/labels", {
      name: args.name,
      color: args.color,
      idBoard: bid,
    })
    return JSON.stringify({ id: label.id, name: label.name, color: label.color })
  },
})

export const list = tool({
  description: "List all cards in a Trello list",
  args: {
    listId: tool.schema.string().describe("ID of the Trello list to list cards from"),
  },
  async execute(args) {
    const cards = await apiGet<Record<string, unknown>[]>(
      `/lists/${args.listId}/cards?fields=id,name,desc,due,url,idLabels,idChecklists`,
    )
    return JSON.stringify(
      cards.map((c) => ({
        id: c.id,
        name: c.name,
        desc: c.desc,
        due: c.due,
        url: c.url,
        idLabels: c.idLabels,
        idChecklists: c.idChecklists,
      })),
    )
  },
})

export const checklists = tool({
  description: "Get checklists of a Trello card",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to get checklists from"),
  },
  async execute(args) {
    const cl = await apiGet<Record<string, unknown>[]>(`/cards/${args.cardId}/checklists`)
    return JSON.stringify(
      cl.map((c) => ({
        id: c.id,
        name: c.name,
        checkItems: (c.checkItems as Array<Record<string, unknown>>).map((i) => ({
          id: i.id,
          name: i.name,
          state: i.state,
        })),
      })),
    )
  },
})

export const comments = tool({
  description: "Get comments of a Trello card",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to get comments from"),
  },
  async execute(args) {
    const actions = await apiGet<Record<string, unknown>[]>(
      `/cards/${args.cardId}/actions?filter=commentCard`,
    )
    return JSON.stringify(
      actions.map((a) => ({
        id: a.id,
        date: a.date,
        text: (a.data as Record<string, unknown>).text,
        memberCreator: (a.memberCreator as Record<string, unknown>).username,
      })),
    )
  },
})

export const addComment = tool({
  description: "Add a comment to a Trello card",
  args: {
    cardId: tool.schema.string().describe("ID of the Trello card to add a comment to"),
    text: tool.schema.string().describe("Text of the comment to add"),
  },
  async execute(args) {
    const result = await apiPost<Record<string, unknown>>(`/cards/${args.cardId}/actions/comments`, {
      text: args.text,
    })
    return JSON.stringify({
      id: result.id,
      date: result.date,
      text: (result.data as Record<string, unknown>).text,
    })
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
    const result = await apiPut<Record<string, unknown>>(
      `/cards/${args.cardId}/actions/${args.commentId}/comments`,
      { text: args.text },
    )
    return JSON.stringify({
      id: result.id,
      date: result.date,
      text: (result.data as Record<string, unknown>).text,
    })
  },
})
