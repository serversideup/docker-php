<template>
    <div class="my-16 xl:max-w-none">
        <!-- <Heading level={2} id="guides">
            Guides
        </Heading> -->
        <div class="not-prose mt-4 grid grid-cols-1 gap-8 border-t border-zinc-900/5 pt-10 dark:border-white/5 sm:grid-cols-2 xl:grid-cols-4">
            <div v-for="guide in guides"
                :key="guide.href">
                <h3 class="text-sm font-semibold text-zinc-900 dark:text-white">
                    {{ guide.name }}
                </h3>
                <p class="mt-1 text-sm text-zinc-600 dark:text-zinc-400">
                    {{ guide.description }}
                </p>
                <p class="mt-4">
                    <AppLink :href="guide.href" :variant="'text'" :arrow="'right'">
                        Read More
                    </AppLink>
                </p>
            </div>
        </div>
    </div>
</template>

<script setup>
const guides = ref([
    {
        href: '/authentication',
        name: 'Authentication',
        description: 'Learn how to authenticate your API requests.',
    },
    {
        href: '/pagination',
        name: 'Pagination',
        description: 'Understand how to work with paginated responses.',
    },
    {
        href: '/errors',
        name: 'Errors',
        description: 'Read about the different types of errors returned by the API.',
    },
    {
        href: '/webhooks',
        name: 'Webhooks',
        description: 'Learn how to programmatically configure webhooks for your app.',
    },
])
</script>