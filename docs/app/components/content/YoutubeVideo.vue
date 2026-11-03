<script setup lang="ts">
const props = defineProps<{
  id: string
  title: string
}>()

const src = computed(() => `https://www.youtube-nocookie.com/embed/${props.id}`)
</script>

<template>
  <figure class="not-prose my-8 overflow-hidden rounded-xl border border-default bg-elevated">
    <iframe
      :src="src"
      :title="title"
      class="block aspect-video w-full"
      loading="lazy"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      referrerpolicy="strict-origin-when-cross-origin"
      allowfullscreen
    />
  </figure>
</template>
