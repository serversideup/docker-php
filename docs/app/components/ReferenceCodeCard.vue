<script setup lang="ts">
// Renders through MDC so examples match every other code block on the site:
// the same Shiki theme, file icon, and copy button.
const props = defineProps<{
  filename: string
  language: string
  code: string
}>()

const markdown = computed(() => `\`\`\`${props.language} [${props.filename}]\n${props.code}\n\`\`\``)
</script>

<template>
  <MDC
    :value="markdown"
    tag="div"
    class="min-w-0 self-start [&_pre]:my-0"
  />
</template>
