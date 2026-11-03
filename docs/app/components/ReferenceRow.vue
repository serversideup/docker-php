<script setup lang="ts">
defineProps<{
  name: string
  anchor: string
  open: boolean
  // Variations that use it; leave it out when every variation does
  variations?: string[]
  // Tailwind grid columns for md and up, shared with the list's header row
  columns: string
}>()

defineEmits<{ toggle: [], move: [event: KeyboardEvent, step: number] }>()
</script>

<template>
  <li
    :id="anchor"
    class="scroll-mt-(--row-offset)"
  >
    <div
      class="relative grid grid-cols-[minmax(0,1fr)_1.5rem] items-start gap-x-6 gap-y-1 px-4 py-3 transition-colors hover:bg-elevated/50 has-[[data-row]:focus-visible]:bg-elevated/50"
      :class="[columns, { 'bg-elevated/50': open }]"
    >
      <span class="min-w-0">
        <!-- The name is the row's toggle; its ::after stretches over the whole row. -->
        <button
          type="button"
          class="block max-w-full truncate text-left font-mono text-[13px] font-medium text-highlighted focus-visible:outline-none after:absolute after:inset-0 after:content-['']"
          :aria-expanded="open"
          :aria-controls="`${anchor}-details`"
          data-row
          @click="$emit('toggle')"
          @keydown.down.prevent="$emit('move', $event, 1)"
          @keydown.up.prevent="$emit('move', $event, -1)"
        >
          {{ name }}
        </button>
        <span class="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px]">
          <span
            class="text-dimmed"
            :class="{ 'font-mono': variations }"
          >{{ variations ? variations.join(' · ') : 'All variations' }}</span>
          <slot name="meta" />
        </span>
      </span>

      <UIcon
        name="i-lucide-chevron-right"
        class="pointer-events-none mt-0.5 size-4 text-dimmed transition-transform md:order-last"
        :class="{ 'rotate-90 text-muted': open }"
      />

      <slot />
    </div>

    <div
      v-if="open"
      :id="`${anchor}-details`"
      class="bg-elevated/50 px-4 pb-5"
    >
      <div class="grid gap-5 rounded-lg border border-default bg-default p-4 md:grid-cols-[minmax(0,1fr)_minmax(0,1.1fr)] md:gap-8 md:p-5">
        <slot name="details" />
      </div>
    </div>
  </li>
</template>
