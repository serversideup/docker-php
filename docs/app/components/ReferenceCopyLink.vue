<script setup lang="ts">
defineProps<{ label: string, copied: boolean }>()
defineEmits<{ copy: [] }>()
</script>

<template>
  <UButton
    :icon="copied ? 'i-lucide-check' : 'i-lucide-link'"
    :label="copied ? 'Link copied' : label"
    :color="copied ? 'success' : 'neutral'"
    variant="soft"
    size="sm"
    @click="$emit('copy')"
  />
</template>
