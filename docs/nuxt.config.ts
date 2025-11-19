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
        'nuxt-schema-org',
        './modules/pre-render-raw-routes'
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
                prefix: 'hosts',
                dir: './app/assets/icons/hosts'
            },
            {
                prefix: 'services',
                dir: './app/assets/icons/services'
            }
        ]
    },

    plausible: {
        apiHost: 'https://a.521dimensions.com'
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
            },
            {
                title: 'Image Variations',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/docs/image-variations%' }
                ]
            },
            {
                title: 'Framework Guides',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/docs/framework-guides%' }
                ]
            },
            {
                title: 'Deployment and Production',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/docs/deployment-and-production%' }
                ]
            },
            {
                title: 'Advanced Guides',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/docs/guide%' }
                ]
            },
            {
                title: 'Customizing The Image',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/docs/customizing-the-image%' }
                ]
            },
            {
                title: 'Troubleshooting',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/docs/troubleshooting%' }
                ]
            },
            {
                title: 'Reference',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/docs/reference%' }
                ]
            }
        ]
    },

    site: {
        url: process.env.NUXT_SITE_URL || 'https://serversideup.net/open-source/docker-php/',
        name: process.env.NUXT_SITE_NAME || 'PHP Docker Images (serversideup/php)',
        env: process.env.NUXT_SITE_ENV || 'production',
    },

    ui: {
        colorMode: false
    }
})
