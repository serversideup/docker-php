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
      <ReferenceSearch
        ref="searchInput"
        v-model="search"
        :placeholder="`Search ${variables.length} variables`"
        label="Search environment variables"
        @down="focusRow(0)"
      />

      <div class="flex flex-wrap items-center gap-x-4 gap-y-2 px-4 py-3">
        <div
          class="-mx-1 flex max-w-full gap-1 overflow-x-auto px-1"
          role="radiogroup"
          aria-label="Variation"
        >
          <button
            v-for="item in variationItems"
            :key="item.value"
            type="button"
            role="radio"
            :aria-checked="variation === item.value"
            class="shrink-0 rounded-md px-2.5 py-1 font-mono text-xs transition-colors focus-visible:outline-2 focus-visible:outline-primary"
            :class="variation === item.value ? 'bg-elevated text-highlighted ring ring-inset ring-accented' : 'text-muted hover:text-highlighted'"
            @click="variation = item.value"
          >
            {{ item.label }}
          </button>
        </div>

        <p class="ms-auto text-xs text-dimmed tabular-nums">
          {{ filtered.length === variables.length ? `${variables.length} variables` : `${filtered.length} of ${variables.length}` }}
        </p>
      </div>

      <div
        class="hidden md:grid gap-6 border-t border-default px-4 py-2 text-xs font-medium text-muted"
        :class="COLUMNS"
      >
        <button
          type="button"
          class="inline-flex items-center gap-1 justify-self-start transition-colors hover:text-highlighted focus-visible:outline-2 focus-visible:outline-primary"
          :aria-label="sort === 'name' ? 'Variable, sorted A to Z. Sort Z to A' : 'Variable, sorted Z to A. Sort A to Z'"
          @click="sort = sort === 'name' ? 'name-desc' : 'name'"
        >
          Variable
          <UIcon
            :name="sort === 'name' ? 'i-lucide-arrow-up' : 'i-lucide-arrow-down'"
            class="size-3"
          />
        </button>
        <span>Default</span>
        <span>Description</span>
      </div>
    </div>

    <div
      v-if="!filtered.length"
      class="px-4 py-16 text-center"
    >
      <p class="text-sm text-muted">
        No variables match <span v-if="search">“{{ search }}”</span><span v-else>these filters</span>.
      </p>
      <UButton
        label="Clear filters"
        color="neutral"
        variant="outline"
        size="sm"
        class="mt-4"
        @click="clearFilters"
      />
    </div>

    <ul
      v-else
      ref="list"
      class="divide-y divide-default"
    >
      <ReferenceRow
        v-for="variable in sorted"
        :key="variable.name"
        :name="variable.name"
        :anchor="anchor(variable.name)"
        :open="open === variable.name"
        :variations="variable.variations"
        :columns="COLUMNS"
        @toggle="toggle(variable.name)"
        @move="moveFocus"
      >
        <template #meta>
          <span
            v-if="variable.requires"
            class="inline-flex items-center gap-1 text-dimmed"
          >
            <UIcon
              name="i-lucide-info"
              class="size-3 text-primary"
            />
            Requires <code class="font-mono text-muted">{{ variable.requires }}</code>
          </span>
        </template>

        <span class="col-span-2 md:col-span-1 min-w-0">
          <code class="inline-block max-w-full truncate rounded bg-elevated px-1.5 py-0.5 font-mono text-xs text-toned align-middle">{{ shownDefault(variable) }}</code>
        </span>

        <span
          class="col-span-2 md:col-span-1 min-w-0 text-sm"
          :class="open === variable.name ? 'text-default' : 'text-muted md:truncate'"
        >
          <InlineMarkdown :text="variable.description" />
        </span>

        <template #details>
          <div class="min-w-0 space-y-5">
            <section
              v-if="variable.values"
              class="space-y-2"
            >
              <h3 class="text-xs font-medium text-muted">
                Accepted values
              </h3>
              <ul class="flex flex-wrap gap-1.5">
                <li
                  v-for="value in variable.values"
                  :key="value"
                  class="inline-flex items-center gap-1.5 rounded-md border px-2 py-1 font-mono text-xs"
                  :class="value === effectiveDefault(variable) ? 'border-primary/50 bg-primary/10 text-highlighted' : 'border-default text-toned'"
                >
                  {{ value }}
                  <span
                    v-if="value === effectiveDefault(variable)"
                    class="font-sans text-[11px] text-primary"
                  >default</span>
                </li>
              </ul>
            </section>

            <section
              v-if="variable.variation_defaults"
              class="space-y-2"
            >
              <h3 class="text-xs font-medium text-muted">
                Default by variation
              </h3>
              <ul class="text-sm">
                <li
                  v-for="(value, name) in variable.variation_defaults"
                  :key="name"
                  class="flex items-center justify-between gap-4 border-b border-default py-1.5"
                >
                  <span class="font-mono text-xs text-toned">{{ name }}</span>
                  <code class="font-mono text-xs text-highlighted">{{ value }}</code>
                </li>
                <li class="flex items-center justify-between gap-4 py-1.5">
                  <span class="text-xs text-muted">Everything else</span>
                  <code class="font-mono text-xs text-highlighted">{{ formatValue(variable.default) }}</code>
                </li>
              </ul>
            </section>

            <ReferenceUsedBy :variations="variable.variations" />

            <ReferenceFurtherReading
              v-if="variable.reference"
              v-bind="variable.reference"
            />

            <p
              v-if="variable.requires"
              class="flex items-start gap-2 rounded-md bg-warning/10 px-3 py-2 text-sm text-toned"
            >
              <UIcon
                name="i-lucide-info"
                class="mt-0.5 size-4 shrink-0 text-warning"
              />
              <span>Only takes effect when <code class="font-mono text-xs text-highlighted">{{ variable.requires }}=true</code>.</span>
            </p>

            <ReferenceCopyLink
              label="Copy link to this variable"
              :copied="copiedKey === `${variable.name}-link`"
              @copy="copyText(`${variable.name}-link`, linkTo(variable.name))"
            />
          </div>

          <ReferenceCodeCard
            filename="compose.yml"
            language="yaml"
            :code="composeSnippet(variable)"
          />
        </template>
      </ReferenceRow>
    </ul>
  </div>
</template>

<script setup lang="ts">
type Variable = {
  name: string
  default: string | null
  variation_defaults?: Record<string, string>
  variations?: string[]
  requires?: string
  values?: string[]
  description: string
  reference?: { label: string, url: string }
}

type Sort = 'name' | 'name-desc'

const COLUMNS = 'md:grid-cols-[minmax(0,15fr)_minmax(0,8fr)_minmax(0,20fr)_1.5rem]'
const VARIATIONS = ['cli', 'fpm', 'fpm-nginx', 'fpm-apache', 'frankenphp']
const SORTS: Sort[] = ['name', 'name-desc']

const { data } = await useAsyncData('env-vars', () => queryCollection('envVars').first())

const variables = computed<Variable[]>(() => data.value?.variables ?? [])

const search = ref('')
const variation = ref('all')
const sort = ref<Sort>('name')
const searchInput = useTemplateRef('searchInput')
const list = useTemplateRef<HTMLUListElement>('list')
const toolbar = useTemplateRef<HTMLElement>('toolbar')

const { open, stickyTop, rowOffset, anchor, toggle, focusRow, moveFocus, copiedKey, copyText, linkTo } = useReferenceList({
  names: computed(() => variables.value.map(variable => variable.name)),
  list,
  toolbar,
  searchInput
})

const variationItems = [{ label: 'All', value: 'all' }, ...VARIATIONS.map(value => ({ label: value, value }))]

const filtered = computed(() => {
  const terms = search.value.toLowerCase().split(/\s+/).filter(Boolean)
  return variables.value.filter((variable) => {
    if (variation.value !== 'all' && variable.variations && !variable.variations.includes(variation.value)) return false
    const haystack = [
      variable.name,
      shownDefault(variable),
      variable.description,
      variable.reference?.label ?? '',
      ...(variable.values ?? [])
    ].join(' ').toLowerCase()
    return terms.every(term => haystack.includes(term))
  })
})

const sorted = computed(() => {
  const byName = [...filtered.value].sort((a, b) => a.name.localeCompare(b.name))
  return sort.value === 'name' ? byName : byName.reverse()
})

function formatValue(value: string | null) {
  if (value === null) return 'Unset'
  return value === '' ? '""' : value
}

function effectiveDefault(variable: Variable) {
  const override = variation.value !== 'all' ? variable.variation_defaults?.[variation.value] : undefined
  return override ?? variable.default
}

function shownDefault(variable: Variable) {
  return formatValue(effectiveDefault(variable))
}

// An empty string is not the same as unset, so never suggest one for a variable without a default.
function exampleValue(variable: Variable) {
  return effectiveDefault(variable) ?? variable.values?.[0] ?? '<value>'
}

function composeSnippet(variable: Variable) {
  return `services:\n  php:\n    environment:\n      ${variable.name}: "${exampleValue(variable)}"`
}

function clearFilters() {
  search.value = ''
  variation.value = 'all'
}

const route = useRoute()
const router = useRouter()

// Filters start empty on the server so the prerendered page lists every variable.
onMounted(() => {
  const { q, variation: v, sort: s } = route.query
  if (typeof q === 'string') search.value = q
  if (typeof v === 'string' && VARIATIONS.includes(v)) variation.value = v
  if (typeof s === 'string' && SORTS.includes(s as Sort)) sort.value = s as Sort

  watchDebounced([search, variation, sort], () => {
    const query: Record<string, string> = {}
    if (search.value) query.q = search.value
    if (variation.value !== 'all') query.variation = variation.value
    if (sort.value !== 'name') query.sort = sort.value
    router.replace({ query, hash: open.value ? `#${anchor(open.value)}` : '' })
  }, { debounce: 300 })
})
</script>
