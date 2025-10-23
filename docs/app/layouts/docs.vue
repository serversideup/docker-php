<script setup lang="ts">
import type { ContentNavigationItem } from '@nuxt/content'

const route = useRoute()
const navigationData = inject<Ref<ContentNavigationItem[]>>('navigation')

/**
 * Recursively checks if a navigation item or any of its children contains the active path
 */
function containsActivePath(item: ContentNavigationItem, activePath: string): boolean {
  // Check if this item matches the active path
  // Use both _path and path properties for compatibility
  if (item._path === activePath || item.path === activePath) {
    return true
  }
  
  // Check if any children contain the active path
  if (item.children && item.children.length > 0) {
    return item.children.some(child => containsActivePath(child, activePath))
  }
  
  return false
}

/**
 * Processes navigation items to ensure sections are expanded if:
 * 1. They have defaultOpen: true (or undefined) in .navigation.yml, OR
 * 2. They contain the active page
 */
function processNavigation(items: ContentNavigationItem[], activePath: string): ContentNavigationItem[] {
  return items.map(item => {
    const hasActivePath = containsActivePath(item, activePath)
    
    // Clone the item to avoid mutating the original
    const processedItem = { ...item }
    
    // If this item contains the active path, ensure it's expanded
    // Otherwise, preserve the original defaultOpen value
    if (hasActivePath && item.children && item.children.length > 0) {
      processedItem.defaultOpen = true
    }
    
    // Recursively process children
    if (processedItem.children && processedItem.children.length > 0) {
      processedItem.children = processNavigation(processedItem.children, activePath)
    }
    
    return processedItem
  })
}

// Process the navigation data to expand sections containing the active page
// while preserving defaultOpen settings from .navigation.yml
const navigation = computed(() => {
  const navItems = navigationData?.value?.[0]?.children || []
  return processNavigation(navItems, route.path)
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