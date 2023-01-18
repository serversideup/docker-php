<template>
    <div>
        <NuxtLink :to="'/'">Home</NuxtLink>
        <br>
        <NuxtLink :to="'/docs'">Docs</NuxtLink>

        <ContentQuery
            v-slot="{ data }">
            <ul>
                <li v-for="( page, index ) in data"
                    :key="'doc-'+index">
                    <NuxtLink :href="page._path">
                        {{ page.title }}
                    </NuxtLink>
                </li>
            </ul>
        </ContentQuery>
    </div>
</template>

<script setup>

</script>