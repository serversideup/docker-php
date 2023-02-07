<template>
    <div class="flex">
        <div class="flex flex-col items-start gap-3" v-if="previous != null">
            <DocsPageLink 
              :label="'Previous'" 
              :page="previous" 
              :previous="true"/>
        </div>
        <div class="ml-auto flex flex-col items-end gap-3" v-if="next != null && next._path != '/docs'">
            <DocsPageLink 
              :label="'Next'" 
              :page="next"/>
        </div>
    </div>
</template>

<script setup>
const props = defineProps(['previous', 'next'])
</script>