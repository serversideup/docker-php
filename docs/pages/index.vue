<template>
    <div>
        <NuxtLink :to="'/'">Home</NuxtLink>
        <br>
        <NuxtLink :to="'/docs'">Docs</NuxtLink>
        <br>
        This is the home page
    </div>
</template>

<script setup>
definePageMeta({
    layout: 'marketing'
});
</script>