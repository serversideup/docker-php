// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
    modules: [
        '@nuxt/eslint',
        '@nuxt/image',
        '@nuxt/ui',
        '@nuxt/content',
        '@nuxtjs/plausible',
        '@nuxtjs/sitemap',
        'nuxt-og-image',
        'nuxt-llms',
        'nuxt-schema-org'
    ],

    devtools: {
        enabled: true
    },

    css: ['~/assets/css/main.css'],

    content: {
        build: {
            markdown: {
                toc: {
                    searchDepth: 2
                }
            }
        }
    },

    compatibilityDate: '2024-07-11',

    nitro: {
        prerender: {
            routes: [
                '/'
            ],
            crawlLinks: true,
            autoSubfolderIndex: false
        }
    },

    eslint: {
        config: {
            stylistic: {
                commaDangle: 'never',
                braceStyle: '1tbs'
            }
        }
    },

    icon: {
        provider: 'iconify'
    },

    site: { 
        url: process.env.NUXT_SITE_URL || 'SITE URL',
        name: process.env.NUXT_SITE_NAME || 'SITE NAME',
        env: process.env.NUXT_SITE_ENV || 'production'
    },

    llms: {
        domain: 'https://docs-template.nuxt.dev/',
        title: 'Nuxt Docs Template',
        description: 'A template for building documentation with Nuxt UI and Nuxt Content.',
        full: {
            title: 'Nuxt Docs Template - Full Documentation',
            description: 'This is the full documentation for the Nuxt Docs Template.'
        },
        sections: [
            {
                title: 'Getting Started',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/docs/getting-started%' }
                ]
            },
            {
                title: 'Essentials',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/essentials%' }
                ]
            }
        ]
    },

    ui: {
        colorMode: false
    }
})
