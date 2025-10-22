<script setup lang="ts">
import type { ContentNavigationItem } from '@nuxt/content'

const navigationData = inject<Ref<ContentNavigationItem[]>>('navigation')

// Simply pass through the navigation data
// The defaultOpen property from .navigation.yml will already be included
const navigation = computed(() => {
  return navigationData?.value?.[0]?.children || []
})
</script>

<template>
  <UContainer>
    <UPage>
      <template #left>
        <UPageAside>
          <UContentNavigation
            highlight
            :navigation="navigation"
          />
        </UPageAside>
      </template>

      <slot />
    </UPage>
  </UContainer>
</template>