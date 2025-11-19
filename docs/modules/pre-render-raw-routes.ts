import { addPrerenderRoutes, defineNuxtModule, createResolver } from '@nuxt/kit'
import { readdirSync, statSync } from 'fs'
import { join, relative } from 'path'

export default defineNuxtModule({
    meta: {
        name: 'pre-render-raw-routes',
        configKey: 'preRenderRawRoutes',
    },
    setup(options, nuxt) {
        const { resolve } = createResolver(import.meta.url)
        const contentDir = resolve(nuxt.options.rootDir, 'content/docs')
        
        // Remove leading number and dot from names (e.g., "1.getting-started" -> "getting-started")
        function cleanName(name: string): string {
            return name.replace(/^\d+\./, '')
        }
        
        // Recursively get all .md files
        function getMarkdownFiles(dir: string, basePath: string = ''): string[] {
            const files: string[] = []
            try {
                const entries = readdirSync(dir, { withFileTypes: true })
                for (const entry of entries) {
                    const fullPath = join(dir, entry.name)
                    const cleanedName = cleanName(entry.name)
                    const relativePath = join(basePath, cleanedName)
                    
                    if (entry.isDirectory()) {
                        files.push(...getMarkdownFiles(fullPath, relativePath))
                    } else if (entry.isFile() && entry.name.endsWith('.md') && entry.name !== 'index.md') {
                        const route = `/${relativePath.replace(/\.md$/, '')}`
                        
                        files.push(route)
                    } else if (entry.isFile() && entry.name.endsWith('.md') && entry.name === 'index.md') {
                        const route = `/${relativePath.replace(/\.md$/, '')}`
                        files.push(route)
                    }
                }
            } catch (error) {
                // Directory might not exist or be accessible
                console.warn(`Could not read directory ${dir}:`, error)
            }
            return files
        }
        
        const routes = getMarkdownFiles(contentDir)
        console.log(routes);
        const rawRoutes = routes.map(route => `/raw/docs${route}.md`)
        
        addPrerenderRoutes(rawRoutes)
    },
})
