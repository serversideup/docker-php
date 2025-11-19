<template>
    <video loop autoplay muted playsinline 
        class="w-full mt-8 lg:mt-16" 
        :src="src">
    </video>
</template>

<script setup>
const props = defineProps({
    src: {
        type: String,
        required: true
    }
})
</script>