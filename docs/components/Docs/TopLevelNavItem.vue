<template>
    <li class="md:hidden">
        <NuxtLink :href="href"
            class="block py-1 text-sm text-zinc-600 transition hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white">
                <slot></slot>
        </NuxtLink>
    </li>
</template>

<script setup>
const props = defineProps(['href', 'children']);
</script>
