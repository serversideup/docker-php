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
                        'apache',
                        'jinja',
                        'bash',
                        'diff',
                        'dockerfile',
                        'ini',
                        'json',
                        'nginx',
                        'php',
                        'sh',
                        'yaml',
                    ]
                },
                toc: {
                    searchDepth: 2
                }
            }
        }
    },

    compatibilityDate: '2024-07-11',

    routeRules: {
        '/docs/getting-started/upgrade-guide': { redirect: '../upgrading/upgrade-guide' },
        '/docs/getting-started/changelog': { redirect: 'https://github.com/serversideup/docker-php/releases' },
        '/docs/getting-started/about': { redirect: '../troubleshooting/getting-help' },
        '/docs/guide/migrating-from-official-php-images': { redirect: '../getting-started/migrating-from-official-php-images' },
        '/docs/guide/using-healthchecks-with-laravel': { redirect: '../framework-guides/laravel/health-checks' },
        '/docs/guide/using-s6-overlay': { redirect: '../customizing-the-image/using-s6-overlay' },
        '/docs/guide/understanding-file-permissions': { redirect: '../customizing-the-image/understanding-file-permissions' },
        '/docs/guide/configuring-trusted-proxies': { redirect: '../deployment-and-production/configuring-trusted-proxies' },
        '/docs/guide/major-version-migrations': { redirect: '../upgrading/upgrade-guide#upgrade-to-a-new-major-version' },
        '/docs/guide/production-performance-tuning': { redirect: '../deployment-and-production/production-performance-tuning' },
        '/docs/guide/verifying-images': { redirect: '../security/verifying-images' },
        '/docs/reference/verifying-images': { redirect: '../security/verifying-images' },
        '/docs/reference/vulnerability-scanning': { redirect: '../security/vulnerability-scanning' },
        '/docs/reference/how-images-are-built': { redirect: '../security/how-images-are-built' },
        '/docs/deployment-and-production/development-to-production': { redirect: 'packaging-your-app-for-deployment' }
    },

    nitro: {
        prerender: {
            routes: [
                '/',
                '/docs/getting-started/upgrade-guide',
                '/docs/getting-started/changelog',
                '/docs/getting-started/about',
                '/docs/guide/migrating-from-official-php-images',
                '/docs/guide/using-healthchecks-with-laravel',
                '/docs/guide/using-s6-overlay',
                '/docs/guide/understanding-file-permissions',
                '/docs/guide/configuring-trusted-proxies',
                '/docs/guide/major-version-migrations',
                '/docs/guide/production-performance-tuning',
                '/docs/guide/verifying-images',
                '/docs/reference/verifying-images',
                '/docs/reference/vulnerability-scanning',
                '/docs/reference/how-images-are-built',
                '/docs/deployment-and-production/development-to-production'
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
                title: 'Customizing The Image',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/docs/customizing-the-image%' }
                ]
            },
            {
                title: 'Upgrading',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/docs/upgrading%' }
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
                title: 'Security',
                contentCollection: 'docs',
                contentFilters: [
                    { field: 'path', operator: 'LIKE', value: '/docs/security%' }
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
