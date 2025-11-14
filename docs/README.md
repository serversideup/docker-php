# Documentation & Static Site, generated with Nuxt Content
This is a documentation site built on top of Nuxt Content.

# Docs location
All docs are located in the [./content](./content/docs) folder if you're just looking for the docs in plain text.

## Setup

Ensure you're in the right directory.

```bash
cd docs/
```

Copy over the environment variable example file.

```bash
cp .env.example .env
```

Make sure to install the dependencies:

```bash
yarn install
```

## Development Server

Start the development server on http://localhost:3000

```bash
yarn dev
```

## Production

Build the application for production:

```bash
yarn build
```

Locally preview production build:

```bash
yarn preview
```

Check out the [deployment documentation](https://nuxt.com/docs/getting-started/deployment) for more information.

# Power User Tips
If you're diving deep into the docs, here are some tips to help you out:

## Components
All components are from the [Nuxt UI](https://ui.nuxt.com/) component library, using the [Nuxt UI Documentation Template](https://docs-template.nuxt.dev).

[View the Nuxt UI Documentation Template components →](https://docs-template.nuxt.dev/essentials/prose-components)

## Icons
All icons are from the [Lucide](https://lucide.dev/icons/) icon set. Use the icon name of `i-lucide-<icon-name>` as the value for the `icon` field in the YAML frontmatter.