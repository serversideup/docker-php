<script setup lang="ts">
interface SeverityCounts {
  Critical: number
  High: number
  Medium: number
  Low: number
  Negligible: number
  Unknown: number
}

interface ImageReport {
  image: string
  variation: string
  php: string
  os: string
  digest: string
  scanned_at: string
  counts: SeverityCounts
  fixable: SeverityCounts
}

interface FixableFinding {
  id: string
  severity: 'Critical' | 'High'
  packages: string[]
  images: { image: string, package: string, version: string, fixed_in: string[] }[]
  consecutive_scans: number
}

interface SecurityIndex {
  generated_at: string
  run_url: string
  scanner: { name: string, version: string, db_built: string }
  images: ImageReport[]
  fixable: FixableFinding[]
}

const reportsUrl = 'https://raw.githubusercontent.com/serversideup/docker-php/security-reports/reports'

// Fetched in the browser so the page shows the latest scan without a docs rebuild.
const { data: index, status } = useFetch<SecurityIndex>(`${reportsUrl}/index.json`, {
  server: false,
  lazy: true
})

const search = ref('')

const images = computed(() => {
  const term = search.value.trim().toLowerCase()
  return (index.value?.images ?? [])
    .filter(image => !term || image.image.includes(term))
    .map(image => ({
      ...image,
      fixableCriticalOrHigh: image.fixable.Critical + image.fixable.High
    }))
    .sort((a, b) => b.fixableCriticalOrHigh - a.fixableCriticalOrHigh || a.image.localeCompare(b.image))
})

const columns = [
  { accessorKey: 'image', header: 'Image' },
  { accessorKey: 'counts.Critical', header: 'Critical' },
  { accessorKey: 'counts.High', header: 'High' },
  { accessorKey: 'fixableCriticalOrHigh', header: 'Fixable critical or high' }
]

const formatDate = (value: string) => new Date(value).toLocaleString('en-US', {
  dateStyle: 'medium',
  timeStyle: 'short',
  timeZone: 'UTC'
}) + ' UTC'
</script>

<template>
  <div class="not-prose space-y-6">
    <UAlert
      v-if="status === 'error'"
      color="warning"
      variant="subtle"
      title="The latest scan results could not be loaded"
      :description="`You can read them directly at ${reportsUrl}/index.json.`"
    />

    <p
      v-else-if="!index"
      class="text-muted"
    >
      Loading the latest scan results...
    </p>

    <template v-else>
      <p class="text-sm text-muted">
        Last scanned {{ formatDate(index.generated_at) }} with Grype {{ index.scanner.version }}
        (vulnerability database from {{ formatDate(index.scanner.db_built) }}).
        <ULink
          :to="index.run_url"
          target="_blank"
          class="text-primary"
        >View the scan run</ULink>
      </p>

      <UAlert
        v-if="index.fixable.length === 0"
        color="success"
        variant="subtle"
        icon="i-lucide-shield-check"
        title="No fixable critical or high vulnerabilities"
        description="Every critical or high finding in the published images is one its upstream maintainers have not fixed yet."
      />

      <div
        v-else
        class="space-y-3"
      >
        <h3 class="text-lg font-semibold">
          Fixable critical or high vulnerabilities
        </h3>
        <UCard
          v-for="finding in index.fixable"
          :key="finding.id"
        >
          <div class="flex flex-wrap items-center gap-2">
            <UBadge
              :color="finding.severity === 'Critical' ? 'error' : 'warning'"
              variant="subtle"
            >
              {{ finding.severity }}
            </UBadge>
            <span class="font-mono font-semibold">{{ finding.id }}</span>
            <span class="text-muted">in {{ finding.packages.join(', ') }}</span>
            <UBadge
              v-if="finding.consecutive_scans >= 2"
              color="neutral"
              variant="outline"
            >
              Survived {{ finding.consecutive_scans - 1 }} rebuild{{ finding.consecutive_scans > 2 ? 's' : '' }}
            </UBadge>
          </div>
          <p class="mt-2 text-sm text-muted">
            {{ finding.images.length }} image{{ finding.images.length === 1 ? '' : 's' }} affected,
            fixed in {{ [...new Set(finding.images.flatMap(image => image.fixed_in))].join(', ') }}.
          </p>
        </UCard>
      </div>

      <div class="space-y-3">
        <UInput
          v-model="search"
          icon="i-lucide-search"
          placeholder="Filter images, for example 8.4 or fpm-nginx"
          class="w-full sm:w-96"
        />
        <UTable
          :data="images"
          :columns="columns"
        >
          <template #image-cell="{ row }">
            <ULink
              :to="`${reportsUrl}/images/${row.original.image}.json`"
              target="_blank"
              class="font-mono"
            >
              {{ row.original.image }}
            </ULink>
          </template>
          <template #fixableCriticalOrHigh-cell="{ row }">
            <UBadge
              :color="row.original.fixableCriticalOrHigh > 0 ? 'error' : 'success'"
              variant="subtle"
            >
              {{ row.original.fixableCriticalOrHigh }}
            </UBadge>
          </template>
        </UTable>
      </div>
    </template>
  </div>
</template>
