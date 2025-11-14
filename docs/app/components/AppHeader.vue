<script setup lang="ts">
import type { ContentNavigationItem } from '@nuxt/content'

const navigation = inject<Ref<ContentNavigationItem[]>>('navigation')

const { header } = useAppConfig()
</script>

<template>
  <UHeader
    class="bg-black"
    :ui="{ center: 'flex-1' }"
    :to="header?.to || '/'"
  >
    

    <template
      v-if="header?.logo?.dark || header?.logo?.light || header?.title"
      #title
    >
        <NuxtImg
            v-if="header?.logo?.dark || header?.logo?.light"
            :src="header?.logo?.dark || header?.logo?.light"
            class="w-52 xl:w-72 shrink-0"
        />

      <span v-else-if="header?.title">
        {{ header.title }}
      </span>
    </template>

    <template
      v-else
      #left
    >
      <NuxtLink :to="header?.to || '/'">
        <AppLogo class="w-auto h-6 shrink-0" />
      </NuxtLink>

      <TemplateMenu />
    </template>

    <template #right>
      <UContentSearchButton
        v-if="header?.search"
        class="lg:hidden"
      />

      <UContentSearchButton
      v-if="header?.search"
      :collapsed="false"
      variant="ghost"
      :label="'Search'"
      :size="'xl'"
      :kbds="[]"
      class="hidden lg:flex cursor-pointer font-bold"
    />

      <template v-if="header?.links">
        <UButton
          class="hidden lg:flex font-bold"
          v-for="(link, index) of header.links"
          :key="index"
          v-bind="{ color: 'neutral', variant: 'ghost', ...link }"
        />
      </template>
    </template>

    <template #body>
      <UContentNavigation
        highlight
        :navigation="navigation?.[0]?.children"
      />
    </template>
  </UHeader>
</template>
