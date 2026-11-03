import type { H3Event } from 'h3'
import { queryCollection } from '@nuxt/content/nitro'
import type { Collections } from '@nuxt/content'

type MinimarkNode = [string, Record<string, unknown>, ...(MinimarkNode | string)[]]
type Child = MinimarkNode | string

type Reference = { label: string, url: string }

type Variable = {
  name: string
  default: string | null
  variation_defaults?: Record<string, string>
  variations?: string[]
  requires?: string
  values?: string[]
  description: string
  reference?: Reference
}

type Command = {
  name: string
  summary: string
  variations?: string[]
  root?: boolean
  description?: string
  usage?: string
  options?: { name: string, description: string }[]
  example?: { language: string, filename: string, code: string }
  reference?: Reference
}

// Reference data only uses inline code and links. Build real nodes from them, because
// Markdown left in a text node gets escaped when the page is written back out.
function inline(text: string): Child[] {
  const children: Child[] = []
  const pattern = /\[([^\]]+)\]\(([^)]+)\)|`([^`]+)`/g
  let last = 0
  for (const match of text.matchAll(pattern)) {
    if (match.index > last) children.push(text.slice(last, match.index))
    if (match[3] !== undefined) {
      children.push(['code', {}, match[3]])
    } else {
      const label = match[1] ?? ''
      const content: Child = label.startsWith('`') && label.endsWith('`') ? ['code', {}, label.slice(1, -1)] : label
      children.push(['a', { href: match[2] }, content])
    }
    last = match.index + match[0].length
  }
  if (last < text.length) children.push(text.slice(last))
  return children
}

function table(headings: string[], rows: Child[][][]): MinimarkNode {
  return ['table', {},
    ['thead', {}, ['tr', {}, ...headings.map((label): MinimarkNode => ['th', {}, label])]],
    ['tbody', {}, ...rows.map((cells): MinimarkNode => ['tr', {}, ...cells.map((cell): MinimarkNode => ['td', {}, ...cell])])]
  ]
}

const byName = <T extends { name: string }>(items: T[]) => [...items].sort((a, b) => a.name.localeCompare(b.name))

function variableNodes(variables: Variable[]): MinimarkNode[] {
  const rows = byName(variables).map((variable) => {
    const defaults: Child[] = [variable.default === null ? 'Unset' : ['code', {}, variable.default === '' ? '""' : variable.default]]
    for (const [name, value] of Object.entries(variable.variation_defaults ?? {})) {
      defaults.push(', ', ['code', {}, value], ' on ', ['code', {}, name])
    }
    const notes = [variable.description]
    if (variable.values) notes.push(`Values: ${variable.values.map(value => `\`${value}\``).join(', ')}.`)
    if (variable.requires) notes.push(`Needs \`${variable.requires}=true\`.`)
    if (variable.reference) notes.push(`Further reading: [${variable.reference.label}](${variable.reference.url}).`)

    return [
      [['code', {}, variable.name] as MinimarkNode],
      defaults,
      [(variable.variations ?? ['all']).join(', ')],
      inline(notes.join(' '))
    ]
  })
  return [table(['Variable', 'Default', 'Variations', 'Description'], rows)]
}

function commandNodes(commands: Command[]): MinimarkNode[] {
  return byName(commands).flatMap((command) => {
    const notes = [command.summary]
    if (command.description) notes.push(command.description)
    notes.push(`Variations: ${(command.variations ?? ['all']).join(', ')}.`)
    if (command.root) notes.push('Needs `USER root`.')
    if (command.reference) notes.push(`Further reading: [${command.reference.label}](${command.reference.url}).`)

    const nodes: MinimarkNode[] = [
      ['h2', { id: command.name }, command.name],
      ['p', {}, ...inline(notes.join(' '))]
    ]
    if (command.usage) nodes.push(['pre', { language: 'bash', code: command.usage }, ['code', {}, command.usage]])
    if (command.options) nodes.push(table(['Option', 'Description'], command.options.map(option => [[['code', {}, option.name] as MinimarkNode], inline(option.description)])))
    if (command.example) {
      const { language, filename, code } = command.example
      nodes.push(['pre', { language, filename, code }, ['code', {}, code]])
    }
    return nodes
  })
}

const COMPONENTS: Record<string, (event: H3Event) => Promise<MinimarkNode[]>> = {
  'env-var-explorer': async (event) => {
    const data = await queryCollection(event, 'envVars' as keyof Collections).first() as { variables: Variable[] } | null
    return data ? variableNodes(data.variables) : []
  },
  'command-explorer': async (event) => {
    const data = await queryCollection(event, 'commands' as keyof Collections).first() as { commands: Command[] } | null
    return data ? commandNodes(data.commands) : []
  }
}

// The explorers render from content/data/*.yml in the browser. Markdown outputs
// (the raw page and llms-full.txt) get the same data as plain Markdown instead.
export async function expandReferenceComponents(event: H3Event, body: { value: unknown[] } | undefined) {
  if (!body) return
  for (const [tag, build] of Object.entries(COMPONENTS)) {
    const index = body.value.findIndex(node => Array.isArray(node) && node[0] === tag)
    if (index !== -1) body.value.splice(index, 1, ...await build(event))
  }
}
