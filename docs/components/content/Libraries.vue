<template>
    <div class="my-16 xl:max-w-none">
        <!-- <Heading level={2} id="official-libraries">
            Official libraries
        </Heading> -->
        <div class="not-prose mt-4 grid grid-cols-1 gap-x-6 gap-y-10 border-t pt-10 border-white/5 sm:grid-cols-2 xl:max-w-none xl:grid-cols-3">
            <div v-for="library in libraries" :key="library.name" class="flex flex-row-reverse gap-6">
                <div class="flex-auto">
                    <h3 class="text-sm font-semibold text-white">
                        {{ library.name }}
                    </h3>
                    <p class="mt-1 text-sm text-zinc-400">
                        {{ library.description }}
                    </p>
                    <p class="mt-4">
                        <AppLink :href="library.href"
                            :variant="'text'"
                            :arrow="'right'">
                                Read more
                        </AppLink>
                    </p>
                </div>
                <img
                    :src=library.logo
                    alt=""
                    class="h-12 w-12"/>
            </div>
        </div>
    </div>
</template>

<script setup>
const libraries = ref([
    {
        href: '#',
        name: 'PHP',
        description: 'A popular general-purpose scripting language that is especially suited to web development.',
        logo: '/images/logos/php.svg',
    },
    {
        href: '#',
        name: 'Ruby',
        description: 'A dynamic, open source programming language with a focus on simplicity and productivity.',
        logo: '/images/logos/ruby.svg',
    },
    {
        href: '#',
        name: 'Node.js',
        description: 'Node.js® is an open-source, cross-platform JavaScript runtime environment.',
        logo: '/images/logos/node.svg',
    },
    {
        href: '#',
        name: 'Python',
        description: 'Python is a programming language that lets you work quickly and integrate systems more effectively.',
        logo: '/images/logos/python.svg',
    },
    {
        href: '#',
        name: 'Go',
        description: 'An open-source programming language supported by Google with built-in concurrency.',
        logo: '/images/logos/go.svg',
    },
])
</script>