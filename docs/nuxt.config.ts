// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
    modules: [
        '@nuxt/eslint',
        '@nuxt/image',
        '@nuxt/ui',
        '@nuxt/content',
        '@nuxtjs/plausible',
        '@nuxtjs/sitemap',
        '@vueuse/nuxt',
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
                highlight: {
                    theme: 'github-dark',
                    langs: [
                        'jinja',
                        'bash',
                        'diff',
                        'dockerfile',
                        'nginx',
                        'php',
                    ]
                },
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
        provider: 'iconify',
        customCollections: [
            {
                prefix: 'features',
                dir: './app/assets/icons/features'
            },
            {
                prefix: 'services',
                dir: './app/assets/icons/services'
            }
        ]
    },

    site: { 
        url: process.env.NUXT_SITE_URL || 'SITE URL',
        name: process.env.NUXT_SITE_NAME || 'SITE NAME',
        env: process.env.NUXT_SITE_ENV || 'production'
    },

    llms: {
        domain: 'https://serversideup.net/open-source/docker-php/',
        title: 'PHP Docker Images (serversideup/php)',
        description: 'Production-ready PHP Docker images for Laravel, WordPress, and more.',
        full: {
            title: 'PHP Docker Images (serversideup/php) - Full Documentation',
            description: 'Production-ready PHP Docker images for Laravel, WordPress, and more.'
        },
        sections: [
            {
                title: 'Getting Started',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/docs/getting-started%' }
                ]
            }
        ]
    },

    ui: {
        colorMode: false
    }
})
