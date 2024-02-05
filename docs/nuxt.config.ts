import tailwindTypography from '@tailwindcss/typography'

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
    modules: [
        'nuxt-og-image',
        '@nuxtjs/algolia',
        '@nuxtjs/color-mode',
        '@nuxt/content',
        '@nuxtjs/plausible',
        '@nuxtjs/tailwindcss',
        '@vueuse/nuxt'
    ],

    algolia: {
        apiKey: process.env.ALGOLIA_SEARCH_API_KEY,
        applicationId: process.env.ALGOLIA_APPLICATION_ID,

        docSearch: {
            indexName: process.env.ALGOLIA_INDEX
        }
    },

    content: {
        documentDriven: true,

        markdown: {
            tags: {
                h2: 'AppHeading2',
                h3: 'AppHeading3',
                h4: 'AppHeading4'
            }
        },

        highlight: {
            theme: {
              // Default theme (same as single string)
              default: 'github-dark',
              // Theme used if `html.dark`
              dark: 'github-dark',
              // Theme used if `html.sepia`
              sepia: 'monokai'
            },

            preload: [
                'dockerfile',
                'php'
            ]
        },

        
    },

    colorMode: {
        classSuffix: ''
    },

    nitro: {
        prerender: {
            routes: ['/sitemap.xml']
        }
    },

    ogImage: {
        componentDirs: ['~/components/Global/OgImage'],
    },

    plausible: {
        apiHost: 'https://a.521dimensions.com'
    },

    runtimeConfig: {
        public: {
            basePath: process.env.NUXT_APP_BASE_URL || '/',
            domain: process.env.TOP_LEVEL_DOMAIN
        }
    },

    site: {
        url: process.env.BASE_PATH,
    },

    tailwindcss: {
        config: {
            plugins: [tailwindTypography]
        },
        cssPath: '~/assets/css/tailwind.css',
    }
})
