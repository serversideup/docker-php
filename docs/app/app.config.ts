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
        pageCard: {
            slots: {
                leadingIcon: 'size-12 text-primary-500', // Bigger icon with primary color
                title: 'text-xl font-bold text-white mb-2', // Larger, bold title
                description: 'text-gray-300 text-md leading-relaxed' // Styled description
            }
        },
        prose: {
            codeIcon: {
                'compose.yml': 'i-services-docker',
                'compose.yaml': 'i-services-docker',
                'custom-nginx.conf': 'i-services-nginx',
                'deployment.yaml': 'i-services-kubernetes',
                'deployment.yml': 'i-services-kubernetes',
                'docker-compose.yaml': 'i-services-docker',
                'docker-compose.yml': 'i-services-docker',
                'dockerfile': 'i-services-docker',
                'Dockerfile': 'i-services-docker',
                'nginx.conf': 'i-services-nginx',
                'Terminal': 'i-ph-terminal-window-duotone'
            },
            callout: {
                slots: {
                    base: 'text-white [&_a]:text-white [&_a]:hover:text-white [&_a]:hover:border-white'
                },
                variants: {
                    color: {
                        primary: {
                            base: '[&_a]:text-white [&_a]:hover:text-white [&_a]:hover:border-white'
                        },
                        secondary: {
                            base: '[&_a]:text-white [&_a]:hover:text-white [&_a]:hover:border-white'
                        },
                        success: {
                            base: '[&_a]:text-white [&_a]:hover:text-white [&_a]:hover:border-white'
                        },
                        info: {
                            base: '[&_a]:text-white [&_a]:hover:text-white [&_a]:hover:border-white'
                        },
                        warning: {
                            base: '[&_a]:text-white [&_a]:hover:text-white [&_a]:hover:border-white'
                        },
                        error: {
                            base: '[&_a]:text-white [&_a]:hover:text-white [&_a]:hover:border-white'
                        },
                        neutral: {
                            base: '[&_a]:text-white [&_a]:hover:text-white [&_a]:hover:border-white'
                        }
                    }
                }
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
        },
    },
    seo: {
        siteName: 'PHP Docker Images (serversideup/php)'
    },
    header: {
        title: 'PHP Docker Images (serversideup/php)',
        to: '/',
        logo: {
            alt: 'PHP Docker Images (serversideup/php)',
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
        credits: `⚡️ Powered by Server Side Up`,
        colorMode: false,
        links: [{
            'icon': 'i-simple-icons-discord',
            'to': 'https://serversideup.net/discord',
            'target': '_blank',
            'aria-label': 'Server Side Up on Discord'
        }, {
            'icon': 'i-simple-icons-x',
            'to': 'https://x.com/serversideup',
            'target': '_blank',
            'aria-label': 'Server Side Up on X'
        }, {
            'icon': 'i-simple-icons-github',
            'to': 'https://github.com/serversideup/',
            'target': '_blank',
            'aria-label': 'Server Side Up on GitHub'
        }]
    },
    toc: {
        title: 'Table of Contents',
        bottom: {
            title: 'Community',
            edit: 'https://github.com/serversideup/docker-php/edit/main/docs/content',
            links: [
                {
                    icon: 'i-lucide-star',
                    label: 'Star on GitHub',
                    to: 'https://github.com/serversideup/docker-php',
                    target: '_blank'
                },
                {
                    icon: 'i-lucide-bell-ring',
                    label: 'Subscribe',
                    to: 'https://serversideup.net/subscribe',
                    target: '_blank'
                },
                {
                    icon: 'i-lucide-handshake',
                    label: 'Professional Help',
                    to: 'https://serversideup.net/professional-support',
                    target: '_blank'
                }
            ]
        }
    }
})
