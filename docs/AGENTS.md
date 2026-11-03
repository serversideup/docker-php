# Documentation guidelines

The docs and marketing site for `serversideup/php`. It is a static Nuxt 4 site built with Nuxt Content and Nuxt UI. Pages are Markdown in `content/docs/`; the home page is `content/index.md`.

```bash
yarn install
yarn dev        # http://localhost:3000
yarn generate   # static build; fails on dead internal links
```

## Facts come from the code

Every option name, default, path, and port must match `src/` and `scripts/conf/php-versions-base-config.yml`. Check the source before writing, never memory or another docs page.

Each fact has one home. Other pages link to it instead of repeating it:

| Fact | Page |
|---|---|
| Environment variables, defaults, and which variations use them | `content/data/env-vars.yml`, rendered on `9.reference/1.environment-variable-specification.md`. `scripts/check-env-var-docs.sh` fails CI when it drifts from `src/`. |
| Helper commands, their usage, and which variations ship them | `content/data/commands.yml`, rendered on `9.reference/2.command-reference.md`. `scripts/check-command-docs.sh` fails CI when it drifts from `src/`. |
| Variations, PHP versions, operating systems, and tags | `1.getting-started/5.choosing-an-image.md` |
| Floating and pinned tags, release model | `6.upgrading/1.upgrade-guide.md` |
| SSL modes and certificates | `4.deployment-and-production/2.configuring-ssl.md` |
| The web server health check and `HEALTHCHECK_PATH` | `4.deployment-and-production/3.health-checks.md` |
| Laravel worker health check scripts | `3.framework-guides/1.laravel/3.health-checks.md` |
| Worker stop signals and the `AUTORUN_ENABLED` warning | `3.framework-guides/1.laravel/2.workers.md` |
| Entrypoint script order | `5.customizing-the-image/3.adding-your-own-start-up-scripts.md` |
| OPcache and PHP-FPM tuning | `4.deployment-and-production/5.production-performance-tuning.md` |
| How images are built and published | `8.security/1.how-images-are-built.md` |

A page may repeat a variable's default in a table that has `Variable` and `Default` columns. Start the cell with `` `value` ``, `` `""` `` for empty, or `Unset`. A short note may follow, such as `` `ondemand`, or `dynamic` in `fpm` ``. `scripts/check-env-var-docs.sh` checks those tables against `env-vars.yml`. It doesn't check defaults mentioned in prose, so mention one only when the sentence depends on it. Upgrade pages are the exception: they say what a default used to be and what it changed to.

## Writing style

- Lead with the point. The first sentence says what the page is for or what the reader gets. One or two sentences of why, then the how.
- One job per page. If the title needs an "and", it is two pages.
- Second person, active voice, imperative steps. Paragraphs of one to four sentences.
- Headings in sentence case that say something: "Custom NGINX rules go in `server-opts.d`", not "NGINX Configuration".
- Tables for options and comparisons, numbered lists or `::steps` for ordered steps. Emoji only where they help a table scan (✅ ❌).
- Docs, not marketing. No unverified numbers, no sales copy, no "seamlessly", "powerful", "simply", "just works".
- Some pages persuade as well as inform, because they decide whether someone switches: `content/index.md`, every page in `1.getting-started/` except Installation, Container basics, and Contributing, plus Laravel Automations, Laravel Health checks, and How images are built. Write them like friendly marketing copy: the reader's problem first, headings that make a point, and one fact per sentence. Every claim still needs a source in the code or from the maintainers.
- US English. Few em dashes.

## Examples

- Use Compose by default. Add a `docker run` tab with `::code-group` only when it is shorter or the page is about the CLI.
- Use `8.5` tags (`serversideup/php:8.5-fpm-nginx`). Never `latest` or an old patch tag.
- Containers listen on `8080` and `8443`; `fpm` listens on `9000`. Map host ports explicitly (`80:8080`).
- Every code block has a language and, where it is a file, a filename: ` ```yaml [compose.yml] `.
- An example that can't be tested by reading the source gets run against a built image (`scripts/dev.sh`).

## Components

- Callouts: `::note`, `::tip`, `::warning` (will break), `::caution` (data loss or security). At most one or two per section.
- `::lead-p` for a page's opening paragraph, `::steps{level="4"}`, `::code-group`, `::code-tree{defaultValue="compose.yml"}`.
- Other components live in `app/components/`; check there before inventing markup.

## Files and links

- A number prefix sets the order and is dropped from the URL: `1.getting-started/3.installation.md` is `/docs/getting-started/installation`.
- Every page has `title` and a one-sentence `description` in frontmatter.
- Link to other pages by URL path without prefixes. Full URLs for external links.
- When a page moves or is removed, add its old path to `routeRules` in `nuxt.config.ts` and to `nitro.prerender.routes` so the redirect is generated.
