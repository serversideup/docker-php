<template>
  <ContentDoc :path="route.path" 
      class="prose dark:prose-invert" 
      tag="article" />
</template>

<script setup>
definePageMeta({
  layout: 'docs',
})

const route = useRoute();

</script>