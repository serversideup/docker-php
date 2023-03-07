<template>
    <section class="mx-auto max-w-[940px] flex flex-col px-6 py-8 lg:py-16">
        <h2 class="font-inter text-white font-bold text-[28px] leading-[28px] text-center mb-16 lg:text-5xl lg:leading-[48px]">
            These are <span class="text-pink-500">very different</span> from other PHP Docker Images.
        </h2>

        <div class="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            <div v-for="(feature, index) in features"
                :key="'feature-'+index"
                class="p-4 bg-gray-900 rounded-lg flex flex-col">
                    <img :src="feature.image" class="w-11 h-11 mb-2"/>  
                    <span class="font-inter text-lg text-slate-50 font-bold mb-2">{{ feature.title }}</span>
                    <span class="font-inter text-slate-300 text-base">{{ feature.description }}</span>
            </div>
        </div>
    </section>
</template>

<script setup>
const features = reactive([
    {
        title: 'Production-ready',
        description: 'Built to be performant and secure to exist on the wild web.',
        image: '/images/icons/rocket-square.svg'
    },
    {
        title: 'Native Health Checks',
        description: 'Be 100% confident your application is actually running.',
        image: '/images/icons/heart-square.svg'
    },
    {
        title: 'High Performance',
        description: 'These images perform faster than the official PHP images.',
        image: '/images/icons/lightning-square.svg'
    },
    {
        title: 'Customizable & Flexible',
        description: 'Environment variables make customizations a breeze.',
        image: '/images/icons/stars-square.svg'
    },
    {
        title: 'Built on Ubuntu 22.04',
        description: 'Work in a familiar and powerful operating system environment.',
        image: '/images/icons/ubuntu-square.svg'
    },
    {
        title: 'Built with Ondřej PHP',
        description: 'All packages are sourced from the highly reliable Ondřej PHP repo.',
        image: '/images/icons/shield-square.svg'
    },
    {
        title: 'NGINX + PHP-FPM',
        description: 'We offer NGINX + PHP-FPM support out of the box.',
        image: '/images/icons/nginx-square.svg'
    },
    {
        title: 'Unified Logging',
        description: 'All logs are directed to STDOUT & STDERR for centralized output.',
        image: '/images/icons/logging-square.svg'
    },
    {
        title: 'Built with S6 Overlay',
        description: 'An extremely intelligent and powerful method to running PHP.',
        image: '/images/icons/heartbeat-square.svg'
    }
])

</script>