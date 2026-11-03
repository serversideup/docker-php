import type { H3Event } from 'h3'

export default defineNitroPlugin((nitroApp) => {
  // Nuxt Content calls this for every page right before writing it into llms-full.txt.
  nitroApp.hooks.hook('content:llms:generate:document' as never, async (event: H3Event, doc: { body?: { value: unknown[] } }) => {
    await expandReferenceComponents(event, doc.body)
  })
})
