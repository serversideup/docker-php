<script setup lang="ts">
defineProps<{ label: string, url: string }>()
</script>

<template>
  <section class="space-y-2">
    <h3 class="text-xs font-medium text-muted">
      Further reading
    </h3>
    <NuxtLink
      :to="url"
      :target="isExternal(url) ? '_blank' : undefined"
      class="group/link inline-flex max-w-full items-center gap-2 rounded-md border border-default bg-elevated/40 px-2.5 py-1.5 text-sm transition-colors hover:border-accented hover:bg-elevated focus-visible:outline-2 focus-visible:outline-primary"
    >
      <UIcon
        name="i-lucide-book-open"
        class="size-4 shrink-0 text-muted"
      />
      <span class="truncate font-mono text-xs text-highlighted">{{ label }}</span>
      <span class="shrink-0 text-xs text-muted">{{ referenceSource(url) }}</span>
      <UIcon
        :name="isExternal(url) ? 'i-lucide-arrow-up-right' : 'i-lucide-arrow-right'"
        class="size-3.5 shrink-0 text-muted transition-colors group-hover/link:text-highlighted"
      />
    </NuxtLink>
  </section>
</template>
