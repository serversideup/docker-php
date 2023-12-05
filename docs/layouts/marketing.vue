<template>
    <div class="w-full flex flex-col min-h-screen bg-black">
        <Head>
            <Link rel="preconnect" href="https://fonts.googleapis.com"/>
            <Link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
            <Link href="https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500;600;700;800;900&display=swap" rel="stylesheet"/>
            <Link rel="apple-touch-icon" sizes="180x180" href="/open-source/docker-php/images/favicon/apple-touch-icon.png"/>
            <Link rel="icon" type="image/png" sizes="32x32" href="/open-source/docker-php/images/favicon/favicon-32x32.png"/>
            <Link rel="icon" type="image/png" sizes="16x16" href="/open-source/docker-php/images/favicon/favicon-16x16.png"/>
            <Link rel="manifest" href="/open-source/docker-php/images/favicon/site.webmanifest"/>
            <Link rel="mask-icon" href="/open-source/docker-php/images/favicon/safari-pinned-tab.svg" color="#5bbad5"/>
            <Meta name="msapplication-TileColor" content="#da532c"/>
            <Meta name="theme-color" content="#ffffff"/>
        </Head>
        
        <GlobalServerSideUp
            :fixed="true"/>

        <MarketingHeader
            :fixed="true"/>
            
        <div class="w-full flex flex-col">
            <slot></slot>
        </div>
    </div>
</template>

<script setup>
useHead({
    htmlAttrs: {
        lang: 'en'
    },
    bodyAttrs: {
        class: 'antialiased'
    },
    title: 'PHP Docker Images (serversideup/php) - Server Side Up',
    script: [
        {
            src: 'https://f.convertkit.com/ckjs/ck.5.js'
        }
    ]
})

const route = useRoute();
const { basePath, domain } = useRuntimeConfig().public;

useSeoMeta({
    ogLocale: 'en_US',
    ogUrl: domain+basePath+route.path,
    ogType: 'website',
    ogSiteName: 'Server Side Up - Docker PHP',
    ogTitle: 'Server Side Up - Docker PHP',
    ogDescription: 'Stop the headache from debugging. Get production-ready PHP Docker Images that help you replicate your application, no matter the environment.',
    ogImage: domain+basePath+'/images/social-image.jpg',
    ogImageWidth: 1200,
    ogImageHeight: 675,
    ogImageType: 'image/jpg',
    twitterCard: 'summary_large_image',
    twitterDescription: 'Stop the headache from debugging. Get production-ready PHP Docker Images that help you replicate your application, no matter the environment.',
    twitterImage: domain+basePath+'/images/social-image.jpg',
    twitterSite: '@serversideup',
    twitterTitle: 'Server Side Up - Docker PHP'
})

</script>