<script setup lang="ts">
import { NuxtLink } from '#components'

// Reference data only uses inline code and links, so a small parser avoids rendering Markdown at runtime.
const props = defineProps<{ text: string }>()

const parts = computed(() => {
  const result: { text: string, code?: boolean, href?: string }[] = []
  const pattern = /\[([^\]]+)\]\(([^)]+)\)|`([^`]+)`/g
  let last = 0
  for (const match of props.text.matchAll(pattern)) {
    if (match.index > last) result.push({ text: props.text.slice(last, match.index) })
    if (match[3] !== undefined) result.push({ text: match[3], code: true })
    else result.push({ text: (match[1] ?? '').replaceAll('`', ''), href: match[2] })
    last = match.index + match[0].length
  }
  if (last < props.text.length) result.push({ text: props.text.slice(last) })
  return result
})
</script>

<template>
  <template
    v-for="(part, index) in parts"
    :key="index"
  >
    <code
      v-if="part.code"
      class="rounded bg-elevated px-1 py-px font-mono text-[0.85em] text-toned"
    >{{ part.text }}</code>
    <component
      :is="NuxtLink"
      v-else-if="part.href"
      :to="part.href"
      :target="isExternal(part.href) ? '_blank' : undefined"
      class="relative z-10 text-primary hover:underline"
    >
      {{ part.text }}
    </component>
    <template v-else>
      {{ part.text }}
    </template>
  </template>
</template>
