<p align="center">
		<img src="https://raw.githubusercontent.com/serversideup/docker-php/main/.github/header.png" width="1200" alt="Docker Images Logo">
</p>
<p align="center">
	<a href="https://actions-badge.atrox.dev/serversideup/docker-php/goto?ref=main"><img alt="Build Status" src="https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fserversideup%2Fdocker-php%2Fbadge%3Fref%3Dmain&style=flat" /></a>
	<a href="https://github.com/serversideup/docker-php/blob/main/LICENSE" target="_blank"><img src="https://badgen.net/github/license/serversideup/docker-php" alt="License"></a>
	<a href="https://github.com/sponsors/serversideup"><img src="https://badgen.net/badge/icon/Support%20Us?label=GitHub%20Sponsors&color=orange" alt="Support us"></a>
</p>

# Available Docker Images
This is a list of the docker images this repository creates:

| ⚙️ Variation | 🎁 Version |
|--------------|------------|
| cli          | [7.4](https://hub.docker.com/r/serversideup/php/tags?name=7.4-cli&page=1&ordering=-name), [8.0](https://hub.docker.com/r/serversideup/php/tags?name=8.0-cli&page=1&ordering=-name)   |
| fpm          | [7.4](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm&page=1&ordering=-name), [8.0](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm&page=1&ordering=-name)   |
| fpm-apache   | [7.4](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm-apache&page=1&ordering=-name), [8.0](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm-apache&page=1&ordering=-name)   |
| fpm-nginx    | [7.4](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm-nginx&page=1&ordering=-name), [8.0](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm-nginx&page=1&ordering=-name)   |

### Usage
Simply use this image name pattern in any of your projects:
```sh
serversideup/php:{{version}}-{{variation-name}}
```
For example... If I wanted to run **PHP 8.0** with **FPM + NGINX**, I would use this image:
```sh
serversideup/php:8.0-fpm-nginx
```

### Updates
✅ The image builds automatically run weekly (Tuesday at 0800 UTC) for latest security updates.

### How these images are built
All images are built off of the official Ubuntu 20.04 docker image. We first build our CLI image, then our FPM, etc. Here is what this looks like:

<img src="https://raw.githubusercontent.com/serversideup/docker-php/main/.github/dependency-diagram.png" alt="Dependency Diagram">

# About this project
We're taking the extra effort to open source as much as we can. Not only could this potentially help someone learn a little bit of Docker, but it makes it a *heck of a lot* easier for us to work with you on new open source ideas.

### Project credits & inspiration

#### [Chris Fidao](https://github.com/fideloper)
Majority of our knowledge came from Chris' course, [Shipping Docker](https://serversforhackers.com/shipping-docker). If you have yet to discover his content, you will be very satisfied with every course he has to offer. He's a great human being and excellent educator.

#### [PHPDocker.io](https://github.com/phpdocker-io/base-images)
This team has an excellent repository and millions of pulls per month. We really like how they structured their code.

# Why these images and not other ones?
Many people have docker images, but they are not runnning them in production. We want to share as much as we can of our production images so we can make it easier to work with you.

We want to make sure that when we work together ***EVERY*** development environment is the same across the board -- no matter how you prefer to work.

# Environment Variables

**Variable Name**|**Used in variation**|**Description**|**Default Value**
:-----:|:-----:|:-----:|:-----:
PHP\_DATE\_TIMEZONE|fpm, fpm-nginx, fpm-apache| |"UTC"
PHP\_DISPLAY\_ERRORS|fpm, fpm-nginx, fpm-apache| |On
PHP\_ERROR\_REPORTING|fpm, fpm-nginx, fpm-apache| |"E\_ALL & ~E\_DEPRECATED & ~E\_STRICT"
PHP\_MEMORY\_LIMIT|fpm, fpm-nginx, fpm-apache| |"256M"
PHP\_MAX\_EXECUTION\_TIME|fpm, fpm-nginx, fpm-apache| |"99"
PHP\_POST\_MAX\_SIZE|fpm, fpm-nginx, fpm-apache| |"100M"
PHP\_UPLOAD\_MAX\_FILE\_SIZE|fpm, fpm-nginx, fpm-apache| |"100M"
PHP\_POOL\_NAME|fpm, fpm-nginx, fpm-apache| |"www"
PHP\_PM\_CONTROL|fpm, fpm-nginx, fpm-apache| |**fpm:** dynamic<br />**fpm-apache:** ondemand<br />**fpm-nginx:** ondemand
PHP\_PM\_MAX\_CHILDREN|fpm, fpm-nginx, fpm-apache| |"5"
PHP\_PM\_START\_SERVERS|fpm, fpm-nginx, fpm-apache| |"2"
PHP\_PM\_MIN\_SPARE\_SERVERS|fpm, fpm-nginx, fpm-apache| |"1"
PHP\_PM\_MAX\_SPARE\_SERVERS|fpm, fpm-nginx, fpm-apache| |"3"

# Submitting issues and pull requests
Since there are a lot of dependencies on these images, please understand that it can make it complicated on mergine your pull request.

We'd love to have your help, but it might be best to explain your intentions first before contributing.

### Like we said -- we're always learning
If you find a critical security flaw, please open an issue or learn more about [our responsible disclosure policy](https://www.notion.so/Responsible-Disclosure-Policy-421a6a3be1714d388ebbadba7eebbdc8).
