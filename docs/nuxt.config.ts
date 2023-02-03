import tailwindTypography from '@tailwindcss/typography'

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
    modules: [
        '@nuxtjs/color-mode',
        '@nuxt/content',
        '@nuxt/image-edge',
        '@nuxtjs/tailwindcss',
        '@vueuse/nuxt'
    ],

    content: {

    },

    colorMode: {
        classSuffix: ''
    },

    tailwindcss: {
        config: {
            plugins: [tailwindTypography]
        },
        cssPath: '~/assets/css/tailwind.css',
    }
})
