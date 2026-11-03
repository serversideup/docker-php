<script setup lang="ts">
defineProps<{ placeholder: string, label: string }>()
defineEmits<{ down: [] }>()

const search = defineModel<string>({ required: true })
const input = useTemplateRef<HTMLInputElement>('input')

defineExpose({ focus: () => input.value?.focus() })
</script>

<template>
  <div class="flex items-center gap-2 px-4 pt-3">
    <UIcon
      name="i-lucide-search"
      class="size-4 shrink-0 text-dimmed"
    />
    <input
      ref="input"
      v-model="search"
      type="search"
      :placeholder="placeholder"
      :aria-label="label"
      class="w-full bg-transparent py-1.5 text-sm text-highlighted placeholder:text-dimmed focus:outline-none [&::-webkit-search-cancel-button]:hidden"
      @keydown.esc="search = ''"
      @keydown.down.prevent="$emit('down')"
    >
    <UButton
      v-if="search"
      icon="i-lucide-x"
      color="neutral"
      variant="ghost"
      size="xs"
      aria-label="Clear search"
      @click="search = ''"
    />
    <UKbd
      v-else
      value="/"
      class="hidden sm:inline-flex"
    />
  </div>
</template>
