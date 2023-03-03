<template>
    <div class="w-full flex flex-col">
        <MarketingHero/>
        <MarketingGrid/>
        <MarketingOptimized/>
        <MarketingDevToProd/>
        <MarketingFollowAlong/>
    </div>
</template>

<script setup>
definePageMeta({
    layout: 'marketing'
});

useHead({
    title: 'PHP Docker Images - Server Side Up'
})

const route = useRoute();
const { basePath, domain } = useRuntimeConfig().public;

useSeoMeta({
    ogLocale: 'en_US',
    ogUrl: domain+route.path,
    ogType: 'website',
    ogSiteName: 'Server Side Up - Docker PHP',
    ogImage: domain+basePath+'/images/og.png',
    ogImageWidth: 1200,
    ogImageHeight: 675,
    ogImageType: 'image/png',
    ogDescription: 'Stop the headache from debugging. Get production-ready PHP Docker Images that help you replicate your application, no matter the environment.',
    twitterCard: 'summary_large_image',
    twitterDescription: 'Stop the headache from debugging. Get production-ready PHP Docker Images that help you replicate your application, no matter the environment.',
    twitterImage: domain+basePath+'/images/og.png',
    twitterSite: '@serversideup'
})
</script>