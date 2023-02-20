<template>
    <div class="w-full min-h-screen bg-black">
        <Head>
            <link rel="apple-touch-icon" sizes="180x180" href="/images/favicon/apple-touch-icon.png">
            <Link rel="icon" type="image/png" sizes="32x32" href="/images/favicon/favicon-32x32.png"/>
            <Link rel="icon" type="image/png" sizes="16x16" href="/images/favicon/favicon-16x16.png"/>
            <Link rel="manifest" href="/images/favicon/site.webmanifest"/>
            <Link rel="mask-icon" href="/images/favicon/safari-pinned-tab.svg" color="#5bbad5"/>
            <Meta name="msapplication-TileColor" content="#da532c"/>
            <Meta name="theme-color" content="#ffffff"/>
        </Head>
        <slot></slot>    
    </div>
</template>

<script setup>
useHead({
    htmlAttrs: {
        lang: 'en'
    },
    bodyAttrs: {
        class: 'antialiased font-inter bg-black'
    }
})
</script>