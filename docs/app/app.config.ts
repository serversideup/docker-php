export default defineAppConfig({
    ui: {
        colors: {
            primary: 'blue',
            neutral: 'neutral'
        },
        banner: {
            slots: {
                icon: 'text-white size-5 shrink-0 pointer-events-none',
                title: 'text-white font-bold text-sm truncate',
            }
        },
        mode: 'dark',
        header: {
            slots: {
                right: 'flex items-center justify-end lg:flex-1 gap-3',
            },
        },
        footer: {
            slots: {
                root: 'border-t border-default',
                left: 'text-sm text-muted'
            }
        }
    },
    seo: {
        siteName: 'PHP Docker Images (serversideup/docker-php)'
    },
    header: {
        title: 'PHP Docker Images (serversideup/docker-php)',
        to: '/',
        logo: {
            alt: 'PHP Docker Images (serversideup/docker-php)',
            light: '/images/php-docker-logo.svg',
            dark: '/images/php-docker-logo.svg'
        },
        search: true,
        links: [{
            'icon': 'i-lucide-book-open',
            'to': '/docs/getting-started',
            'aria-label': 'Documentation',
            'label': 'Docs',
            'variant': 'ghost',
            'size': 'xl',
            'class': 'font-bold'
        },{
            'icon': 'i-simple-icons-discord',
            'to': 'https://serversideup.net/discord',
            'target': '_blank',
            'aria-label': 'Server Side Up on Discord',
            'label': 'Discord',
            'variant': 'ghost',
            'size': 'xl',
            'class': 'font-bold'
        },{
            'icon': 'i-simple-icons-github',
            'to': 'https://github.com/serversideup/docker-php',
            'target': '_blank',
            'aria-label': 'GitHub',
            'label': 'GitHub',
            'variant': 'ghost',
            'size': 'xl',
            'class': 'font-bold'
        },{
            'trailingIcon': 'i-lucide-heart',
            'label': 'Sponsor',
            'to': 'https://github.com/sponsors/serversideup',
            'target': '_blank',
            'aria-label': 'Sponsor',
            'size': 'xl',
            'variant': 'outline',
            'class': 'font-bold',
            
        },{
            'trailingIcon': 'i-lucide-arrow-right',
            'label': 'Get Started',
            'to': '/docs/getting-started',
            'aria-label': 'Get Started',
            'size': 'xl',
            'variant': 'solid',
            'class': 'font-bold',
            'color': 'primary',
        }]
    },
    footer: {
        credits: `Built with Nuxt UI • © ${new Date().getFullYear()}`,
        colorMode: false,
        links: [{
            'icon': 'i-simple-icons-discord',
            'to': 'https://go.nuxt.com/discord',
            'target': '_blank',
            'aria-label': 'Nuxt on Discord'
        }, {
            'icon': 'i-simple-icons-x',
            'to': 'https://go.nuxt.com/x',
            'target': '_blank',
            'aria-label': 'Nuxt on X'
        }, {
            'icon': 'i-simple-icons-github',
            'to': 'https://github.com/serversideup/',
            'target': '_blank',
            'aria-label': 'Nuxt UI on GitHub'
        }]
    },
    toc: {
        title: 'Table of Contents',
        bottom: {
            title: 'Community',
            edit: 'https://github.com/serversideup/docker-php/edit/main/docs/content',
            links: [{
                icon: 'i-lucide-star',
                label: 'Star on GitHub',
                to: 'https://github.com/serversideup/',
                target: '_blank'
            }, {
                icon: 'i-lucide-book-open',
                label: 'Nuxt UI docs',
                to: 'https://ui.nuxt.com/docs/getting-started/installation/nuxt',
                target: '_blank'
            }]
        }
    }
})
