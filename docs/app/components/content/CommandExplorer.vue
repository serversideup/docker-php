<template>
  <div
    class="not-prose rounded-xl border border-default bg-default"
    :style="{ '--row-offset': `${rowOffset}px` }"
  >
    <div
      ref="toolbar"
      class="sm:sticky z-20 rounded-t-xl border-b border-default bg-default/95 backdrop-blur"
      :style="{ top: `${stickyTop}px` }"
    >
      <div class="flex items-center gap-4 pe-4">
        <ReferenceSearch
          ref="searchInput"
          v-model="search"
          :placeholder="`Search ${commands.length} commands`"
          label="Search commands"
          class="flex-1 pb-3"
          @down="focusRow(0)"
        />
        <p class="pt-3 pb-3 text-xs text-dimmed tabular-nums">
          {{ sorted.length === commands.length ? `${commands.length} commands` : `${sorted.length} of ${commands.length}` }}
        </p>
      </div>

      <div
        class="hidden md:grid gap-6 border-t border-default px-4 py-2 text-xs font-medium text-muted"
        :class="COLUMNS"
      >
        <button
          type="button"
          class="inline-flex items-center gap-1 justify-self-start transition-colors hover:text-highlighted focus-visible:outline-2 focus-visible:outline-primary"
          :aria-label="ascending ? 'Command, sorted A to Z. Sort Z to A' : 'Command, sorted Z to A. Sort A to Z'"
          @click="ascending = !ascending"
        >
          Command
          <UIcon
            :name="ascending ? 'i-lucide-arrow-up' : 'i-lucide-arrow-down'"
            class="size-3"
          />
        </button>
        <span>Description</span>
      </div>
    </div>

    <div
      v-if="!sorted.length"
      class="px-4 py-16 text-center"
    >
      <p class="text-sm text-muted">
        No commands match “{{ search }}”.
      </p>
      <UButton
        label="Clear search"
        color="neutral"
        variant="outline"
        size="sm"
        class="mt-4"
        @click="search = ''"
      />
    </div>

    <ul
      v-else
      ref="list"
      class="divide-y divide-default"
    >
      <ReferenceRow
        v-for="command in sorted"
        :key="command.name"
        :name="command.name"
        :anchor="anchor(command.name)"
        :open="open === command.name"
        :variations="command.variations"
        :columns="COLUMNS"
        @toggle="toggle(command.name)"
        @move="moveFocus"
      >
        <template #meta>
          <span
            v-if="command.root"
            class="inline-flex items-center gap-1 text-dimmed"
          >
            <UIcon
              name="i-lucide-info"
              class="size-3 text-primary"
            />
            Requires <code class="font-mono text-muted">USER root</code>
          </span>
        </template>

        <span
          class="col-span-2 md:col-span-1 min-w-0 text-sm"
          :class="open === command.name ? 'text-default' : 'text-muted md:truncate'"
        >
          <InlineMarkdown :text="command.summary" />
        </span>

        <template #details>
          <div class="min-w-0 space-y-5">
            <p
              v-if="command.description"
              class="text-sm leading-relaxed text-toned"
            >
              <InlineMarkdown :text="command.description" />
            </p>

            <section
              v-if="command.usage"
              class="space-y-2"
            >
              <h3 class="text-xs font-medium text-muted">
                Usage
              </h3>
              <code class="block overflow-x-auto whitespace-pre rounded-md bg-elevated px-3 py-2 font-mono text-xs text-highlighted">{{ command.usage }}</code>
            </section>

            <section
              v-if="command.options"
              class="space-y-2"
            >
              <h3 class="text-xs font-medium text-muted">
                Options
              </h3>
              <dl class="divide-y divide-default text-sm">
                <div
                  v-for="option in command.options"
                  :key="option.name"
                  class="grid gap-1 py-2 sm:grid-cols-[10rem_minmax(0,1fr)] sm:gap-4"
                >
                  <dt class="font-mono text-xs text-highlighted">
                    {{ option.name }}
                  </dt>
                  <dd class="text-toned">
                    <InlineMarkdown :text="option.description" />
                  </dd>
                </div>
              </dl>
            </section>

            <ReferenceUsedBy :variations="command.variations" />

            <ReferenceFurtherReading
              v-if="command.reference"
              v-bind="command.reference"
            />

            <p
              v-if="command.root"
              class="flex items-start gap-2 rounded-md bg-warning/10 px-3 py-2 text-sm text-toned"
            >
              <UIcon
                name="i-lucide-info"
                class="mt-0.5 size-4 shrink-0 text-warning"
              />
              <span>The images run as <code class="font-mono text-xs text-highlighted">www-data</code>. Switch to <code class="font-mono text-xs text-highlighted">USER root</code> before this command and back to <code class="font-mono text-xs text-highlighted">USER www-data</code> after it.</span>
            </p>

            <ReferenceCopyLink
              label="Copy link to this command"
              :copied="copiedKey === `${command.name}-link`"
              @copy="copyText(`${command.name}-link`, linkTo(command.name))"
            />
          </div>

          <ReferenceCodeCard
            v-if="command.example"
            v-bind="command.example"
          />
        </template>
      </ReferenceRow>
    </ul>
  </div>
</template>

<script setup lang="ts">
type Command = {
  name: string
  summary: string
  variations?: string[]
  root?: boolean
  description?: string
  usage?: string
  options?: { name: string, description: string }[]
  example?: { language: string, filename: string, code: string }
  reference?: { label: string, url: string }
}

const COLUMNS = 'md:grid-cols-[minmax(0,2fr)_minmax(0,3fr)_1.5rem]'

const { data } = await useAsyncData('commands', () => queryCollection('commands').first())

const commands = computed<Command[]>(() => data.value?.commands ?? [])

const search = ref('')
const ascending = ref(true)
const searchInput = useTemplateRef('searchInput')
const list = useTemplateRef<HTMLUListElement>('list')
const toolbar = useTemplateRef<HTMLElement>('toolbar')

const { open, stickyTop, rowOffset, anchor, toggle, focusRow, moveFocus, copiedKey, copyText, linkTo } = useReferenceList({
  names: computed(() => commands.value.map(command => command.name)),
  list,
  toolbar,
  searchInput
})

const sorted = computed(() => {
  const terms = search.value.toLowerCase().split(/\s+/).filter(Boolean)
  const matches = commands.value
    .filter(command => terms.every(term => [command.name, command.summary, command.description ?? ''].join(' ').toLowerCase().includes(term)))
    .sort((a, b) => a.name.localeCompare(b.name))
  return ascending.value ? matches : matches.reverse()
})
</script>
