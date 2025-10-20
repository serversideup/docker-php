# Documentation & Static Site, generated with Nuxt Content
This is a documentation site built on top of Nuxt Content (v3).

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
