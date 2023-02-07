<template>
    <slot></slot>    
</template>

<script setup>
definePageMeta({
	colorMode: 'dark'
})

useHead({
    htmlAttrs: {
        lang: 'en'
    },
    bodyAttrs: {
        class: 'bg-white antialiased font-inter bg-black dark:bg-black'
    }
})
</script>