<template>
    <div class="w-full">
        <GlobalServerSideUp/>
        <MarketingHeader
            :navigation="navigation[0]"/>
        
        <div class="lg:flex lg:w-screen lg:h-[calc(100vh-126px)]">
            <div style="scrollbar-width: none" class="contents lg:overflow-y-scroll lg:pointer-events-none lg:z-40 lg:flex lg:top-[126px]">
                <div class="contents lg:pointer-events-auto lg:block lg:w-72 lg:overflow-y-auto lg:px-6 lg:pt-4 lg:pb-8 lg:border-white/10 xl:w-80">
                    <DocsNavigation 
                        class="hidden lg:block"
                        :navigation="navigation"
                        :toc="toc"/>
                </div>
            </div>

            <div class="relative px-4 pt-5 sm:px-6 lg:overflow-y-scroll lg:flex-1 lg:px-8">

                <main class="py-8 scroll-smooth" id="content-container">
                    <ContentDoc
                        class="prose prose-invert" 
                        tag="article" />
                </main>

                <DocsFooter
                    :path="route.path"
                    :surround="surround"/>
            </div>
        </div>
    </div>
</template>

<script setup>

definePageMeta({
    layout: 'docs',
})

const route = useRoute();
const { basePath, domain } = useRuntimeConfig().public;
const { data: activePage } = await useAsyncData('active-page', () => queryContent( route.path ).findOne() );

useSeoMeta({
    ogLocale: 'en_US',
    ogUrl: domain+route.path,
    ogType: 'website',
    ogSiteName: 'Server Side Up - Docker PHP',
    ogImage: domain+basePath+'/images/social-image_1200x600.png',
    ogImageWidth: 1200,
    ogImageHeight: 675,
    ogImageType: 'image/png',
    twitterCard: 'summary_large_image',
    twitterDescription: () => activePage.value?.description,
    twitterImage: domain+basePath+'/images/social-image_1200x600.png',
    twitterSite: '@serversideup'
})

const { data: navigation } = await useAsyncData('navigation', () => {
    return fetchContentNavigation();
})

const surround = await queryContent('docs')
                    .only(['_path', 'title'])
                    .findSurround( route.path );

const toc = computed(() => {
    return activePage.value.body.children.filter( (element) => {
        return element.tag == 'h2' || element.tag == 'app-heading-2'
    })
})
</script>
