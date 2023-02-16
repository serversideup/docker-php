<template>
    <div class="w-full min-h-screen bg-black">
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