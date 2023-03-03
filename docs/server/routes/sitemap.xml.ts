import { serverQueryContent } from '#content/server'
import { SitemapStream, streamToPromise } from 'sitemap'
export default defineEventHandler(async (event) => {
    // Fetch all documents
    const docs = await serverQueryContent(event).find()
    const sitemap = new SitemapStream({
        hostname: 'https://serversideup.net'
    })

    // Include landing page
    sitemap.write({
        url: 'https://serversideup.net/open-source/docker-php',
        changefreq: 'monthly'
    })
    

    for (const doc of docs) {
        sitemap.write({
            url: '/open-source/docker-php'+doc._path,
            changefreq: 'monthly'
        })
    }


    sitemap.end()
    return streamToPromise(sitemap)
})