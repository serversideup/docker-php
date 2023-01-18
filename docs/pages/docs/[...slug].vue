<template>
    <div>
        <NuxtLink :to="'/'">Home</NuxtLink>
        <br>
        <NuxtLink :to="'/docs'">Docs</NuxtLink>

        <ContentRenderer :value="doc"/>
    </div>
    
</template>

<script setup>
const { path } = useRoute()
const { data:doc } = await useAsyncData(`content-${path}`, () => {
  return queryContent().where({ _path: path }).findOne()
})
</script>