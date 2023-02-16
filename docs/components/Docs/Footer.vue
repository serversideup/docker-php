<template>
    <footer class="mx-auto max-w-2xl space-y-10 pb-16 lg:max-w-5xl">
        <div class="flex">
            <div class="flex flex-col items-start gap-3" v-if="surround[0] != null">
                <DocsPageLink 
                    :label="'Previous'" 
                    :page="surround[0]" 
                    :previous="true"/>
            </div>
            <div class="ml-auto flex flex-col items-end gap-3" v-if="surround[1] != null && surround[1]._path != '/docs'">
                <DocsPageLink 
                    :label="'Next'" 
                    :page="surround[1]"/>
            </div>
        </div>
    </footer>
</template>

<script setup>
const props = defineProps(['surround']);
</script>