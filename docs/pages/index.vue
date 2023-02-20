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
</script>