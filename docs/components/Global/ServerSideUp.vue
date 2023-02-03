<template>
    <header class="w-full bg-[#1F252C] px-8 py-3">
        <div class="max-w-[1440px] mx-auto flex items-center justify-between">
            <div class="flex items-center">
                <img src="/images/logos/server-side-up-logo-horizontal.svg" class="mr-[2.5rem]"/>
                
                <a class="cursor-pointer font-inter tracking-[.1em] uppercase flex items-center text-[8px] font-bold text-slate-300">
                    Browse Products
                    <svg class="ml-2" width="8" height="5" viewBox="0 0 8 5" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M1 0.985321L4 3.98532L7 0.985321" stroke="#CBD5E1" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                </a>
            </div>

            <div class="flex items-center">
                <nav class="flex gap-6 mr-6">
                    <a v-for="(link, key) in links"
                        :href="link.url"
                        :key="'link-key-'+key"
                        v-text="link.link"
                        class="font-inter tracking-[.1em] uppercase text-[8px] font-bold text-slate-300">
                        
                    </a>
                </nav>
                <nav class="flex gap-[10px]">
                    <a v-for="(link, key) in social"
                        :href="link.url"
                        :key="'link-key-'+key"
                        class="font-inter tracking-[.1em] uppercase text-[8px] font-bold text-slate-300">
                            <img :src="link.icon"/>
                    </a>
                </nav>
            </div>
        </div>
    </header>
</template>

<script setup>
const projects = reactive([

])

const links = reactive([
    {
        url: '',
        link: 'Blog'
    },
    {
        url: '',
        link: 'Community'
    },
    {
        url: '',
        link: 'Courses & Tutorials'
    }
])

const social = reactive([
    {
        url: '',
        icon: '/images/logos/twitter-slate.svg'
    },
    {
        url: '',
        icon: '/images/logos/discord-slate.svg'
    },
    {
        url: '',
        icon: '/images/logos/github-slate.svg'
    }
])
</script>