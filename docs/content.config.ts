import { defineContentConfig, defineCollection, z } from '@nuxt/content'

export default defineContentConfig({
    collections: {
        landing: defineCollection({
            type: 'page',
            source: 'index.md'
        }),
        docs: defineCollection({
            type: 'page',
            source: {
                include: '**',
                exclude: ['index.md', 'data/**']
            },
            schema: z.object({
                redirect: z.string().optional(),
                links: z.array(z.object({
                    label: z.string(),
                    icon: z.string(),
                    to: z.string(),
                    target: z.string().optional()
                })).optional()
            })
        }),
        envVars: defineCollection({
            type: 'data',
            source: 'data/env-vars.yml',
            schema: z.object({
                variables: z.array(z.object({
                    name: z.string(),
                    default: z.string().nullable(),
                    variation_defaults: z.record(z.string(), z.string()).optional(),
                    variations: z.array(z.string()).optional(),
                    requires: z.string().optional(),
                    values: z.array(z.string()).optional(),
                    description: z.string(),
                    reference: z.object({
                        label: z.string(),
                        url: z.string()
                    }).optional()
                }))
            })
        }),
        commands: defineCollection({
            type: 'data',
            source: 'data/commands.yml',
            schema: z.object({
                commands: z.array(z.object({
                    name: z.string(),
                    summary: z.string(),
                    variations: z.array(z.string()).optional(),
                    root: z.boolean().optional(),
                    description: z.string().optional(),
                    usage: z.string().optional(),
                    options: z.array(z.object({
                        name: z.string(),
                        description: z.string()
                    })).optional(),
                    example: z.object({
                        language: z.string(),
                        filename: z.string(),
                        code: z.string()
                    }).optional(),
                    reference: z.object({
                        label: z.string(),
                        url: z.string()
                    }).optional()
                }))
            })
        })
    }
})
