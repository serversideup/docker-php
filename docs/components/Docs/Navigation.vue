<template>
    <nav>
        <ul role="list">
            <DocsNavigationGroup
                v-for="(group, groupIndex) in navigation.children"
                :key="'navigation-group-'+groupIndex"
                :group="group"
                :toc="toc"
                :class="{
                    'md:mt-0': groupIndex === 0
                }"/>

            <li class="sticky bottom-0 z-10 mt-6 min-[416px]:hidden">
                <AppLink :href="'#'" :variant="'filled'" class="w-full">
                    Sign in
                </AppLink>
            </li>
        </ul>
    </nav>
</template>

<script setup>
const props = defineProps(['navigation', 'toc']);
</script>