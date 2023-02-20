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
        markdown: {
            tags: {
                h2: 'AppHeading2',
            }
        },

        highlight: {
            // OR
            theme: {
              // Default theme (same as single string)
              default: 'github-light',
              // Theme used if `html.dark`
              dark: 'github-dark',
              // Theme used if `html.sepia`
              sepia: 'monokai'
            }
        }
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
