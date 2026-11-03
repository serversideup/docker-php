<script setup lang="ts">
defineProps<{ variations?: string[] }>()
</script>

<template>
  <section class="space-y-2">
    <h3 class="text-xs font-medium text-muted">
      Used by
    </h3>
    <p
      v-if="!variations"
      class="inline-flex items-center gap-1.5 text-sm text-toned"
    >
      <UIcon
        name="i-lucide-check"
        class="size-4 text-success"
      />
      Every variation
    </p>
    <ul
      v-else
      class="flex flex-wrap gap-1.5"
    >
      <li
        v-for="name in variations"
        :key="name"
        class="rounded-md bg-elevated px-2 py-1 font-mono text-xs text-toned"
      >
        {{ name }}
      </li>
    </ul>
  </section>
</template>
