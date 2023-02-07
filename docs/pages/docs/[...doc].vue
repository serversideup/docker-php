<template>
    <div class="w-full">
        <GlobalServerSideUp/>
        <MarketingHeader
            :navigation="navigation[0]"/>
        
        <div class="lg:flex lg:w-screen lg:h-[calc(100vh-126px)]">
            <div class="contents lg:overflow-y-scroll lg:pointer-events-none lg:z-40 lg:flex lg:top-[126px]">
                <div class="contents lg:pointer-events-auto lg:block lg:w-72 lg:overflow-y-auto lg:px-6 lg:pt-4 lg:pb-8 lg:dark:border-white/10 xl:w-80">
                    
                    <!-- <div class="hidden lg:flex">
                        <NuxtLink :to="'/'" aria-label="Home">
                            <DocsLogo class="h-6"/>
                        </NuxtLink>
                    </div> -->

                    <!-- <DocsHeader/> -->

                    <DocsNavigation 
                        class="hidden lg:block"
                        :navigation="navigation[0]"
                        :toc="toc"/>
                </div>
            </div>

            <div class="relative px-4 pt-5 sm:px-6 lg:overflow-y-scroll lg:flex-1 lg:px-8">

                <main class="py-8 scroll-smooth" id="content-container">
                    <ContentDoc
                        class="prose dark:prose-invert" 
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

const { data: navigation } = await useAsyncData('navigation', () => {
    return fetchContentNavigation('/docs');
})

const surround = await queryContent('docs')
                    .only(['_path', 'title'])
                    .findSurround( route.path );

const { data: activePage } = await useAsyncData('active-page', () => queryContent( route.path ).findOne() );

const toc = computed(() => {
    return activePage.value.body.children.filter( (element) => {
        return element.tag == 'h2' || element.tag == 'app-heading-2'
    })
})
</script>
