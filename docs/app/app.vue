<template>
    <UApp>
        <NuxtLoadingIndicator />

        <UBanner 
            icon="i-lucide-rocket" 
            title="Spin Pro now available with Laravel Horizon, Reverb, and more!" 
            to="https://getspin.pro/?ref=docker-php"
            color="primary"
            class="text-white"
        />

        <AppHeader />

        <UMain class="bg-neutral-950">
            <NuxtLayout>
                <NuxtPage />
            </NuxtLayout>
        </UMain>

        <AppFooter />

        <ClientOnly>
            <LazyUContentSearch
                :files="files"
                :navigation="navigation"
            />
        </ClientOnly>
  </UApp>
</template>

<script setup lang="ts">
const { seo } = useAppConfig()

const { data: navigation } = await useAsyncData('navigation', () => queryCollectionNavigation('docs'))
const { data: files } = useLazyAsyncData('search', () => queryCollectionSearchSections('docs'), {
    server: false
})

useHead({
    meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1' }
    ],
    link: [
        { rel: 'icon', type: 'image/png', href: '/favicon-96x96.png', sizes: '96x96' },
        { rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' },
        { rel: 'shortcut icon', href: '/favicon.ico' },
        { rel: 'apple-touch-icon', sizes: '180x180', href: '/apple-touch-icon.png' },
        { rel: 'manifest', href: '/site.webmanifest' }
    ],
    htmlAttrs: {
        lang: 'en',
        class: 'dark'
    }
})

useSeoMeta({
    titleTemplate: `%s - ${seo?.siteName}`,
    ogSiteName: seo?.siteName,
    twitterCard: 'summary_large_image'
})

provide('navigation', navigation)
</script>
