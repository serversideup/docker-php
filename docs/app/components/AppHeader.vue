<template>
    <UHeader
        class="bg-neutral-950"
        :ui="{ center: 'flex-1' }"
        :to="header?.to || '/'"
>
        <template
            v-if="header?.logo?.dark || header?.logo?.light || header?.title"
            #title
        >
            <UColorModeImage
                v-if="header?.logo?.dark || header?.logo?.light"
                :light="header?.logo?.light"
                :dark="header?.logo?.dark"
                :alt="header?.logo?.alt"
                class="w-52 xl:w-72 shrink-0"
            />

            <span v-else-if="header?.title">
                {{ header.title }}
            </span>
        </template>

        <template
            v-else
            #left
        >
            <NuxtLink :to="header?.to || '/'">
                <AppLogo class="w-auto h-6 shrink-0" />
            </NuxtLink>
        </template>

        <template #right>
            <UContentSearchButton
                v-if="header?.search"
                variant="ghost"
                :label="'Search'"
                :collapsed="false",
                :size="'xl'"
                :kbds="[]"
                class="cursor-pointer font-bold"
            />

            <template v-if="header?.links">
                <UButton
                    v-for="(link, index) of header.links"
                    :key="index"
                    v-bind="{ color: 'neutral', ...link }"
                />
            </template>
        </template>

        <template #body>
            <UContentNavigation
                highlight
                :navigation="navigation"
            />
        </template>
    </UHeader>
</template>

<script setup>
const navigation = inject('navigation')

const { header } = useAppConfig()
</script>