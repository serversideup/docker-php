<template>
    <footer class="mx-auto max-w-2xl space-y-10 pb-16 lg:max-w-5xl">
        <DocsPageNavigation
            :previous="surround[0]"
            :next="surround[1]"/>
        <DocsSmallPrint/>
    </footer>
</template>

<script setup>
const props = defineProps(['surround']);
</script>