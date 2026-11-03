const SOURCES: Record<string, string> = {
  'www.php.net': 'PHP manual',
  'nginx.org': 'NGINX docs',
  'httpd.apache.org': 'Apache docs',
  'caddyserver.com': 'Caddy docs',
  'frankenphp.dev': 'FrankenPHP docs',
  'letsencrypt.org': 'Let\'s Encrypt',
  'mercure.rocks': 'Mercure docs',
  'github.com': 'GitHub'
}

export function isExternal(url: string) {
  return /^https?:\/\//.test(url)
}

export function referenceSource(url: string) {
  if (!isExternal(url)) return 'Guide'
  const host = new URL(url).hostname
  return SOURCES[host] ?? host
}
