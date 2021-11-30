<p align="center">
		<img src="https://raw.githubusercontent.com/serversideup/docker-php/main/.github/header.png" width="1200" alt="Docker Images Logo">
</p>
<p align="center">
	<a href="https://actions-badge.atrox.dev/serversideup/docker-php/goto?ref=main"><img alt="Build Status" src="https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fserversideup%2Fdocker-php%2Fbadge%3Fref%3Dmain&style=flat" /></a>
	<a href="https://github.com/serversideup/docker-php/blob/main/LICENSE" target="_blank"><img src="https://badgen.net/github/license/serversideup/docker-php" alt="License"></a>
	<a href="https://github.com/sponsors/serversideup"><img src="https://badgen.net/badge/icon/Support%20Us?label=GitHub%20Sponsors&color=orange" alt="Support us"></a>
  <br />
  <a href="https://hub.docker.com/r/serversideup/php/"><img alt="Docker Pulls" src="https://img.shields.io/docker/pulls/serversideup/php"></a>
  <a href="https://community.serversideup.net"><img alt="Discourse users" src="https://img.shields.io/discourse/users?color=blue&server=https%3A%2F%2Fcommunity.serversideup.net"></a>
  <a href="https://discord.gg/9sExfjnJEp"><img alt="Discord" src="https://img.shields.io/discord/910287105714954251?color=blueviolet"></a>
</p>

Hi! We're [Dan](https://twitter.com/danpastori) and [Jay](https://twitter.com/jaydrogers). We're a two person team with a passion for open source products. We created [Server Side Up](https://serversideup.net) to help share what we learn.

### Find us at:

* 📖 [Blog](https://serversideup.net) - get the latest guides and free courses on all things web/mobile development.
* 🙋 [Community](https://community.serversideup.net) - get friendly help from our community members.
* 🤵‍♂️ [Get Professional Help](https://serversideup.net/get-help) - get guaranteed responses within next business day.
* 💻 [GitHub](https://github.com/serversideup) - check out our other open source projects
* 📫 [Newsletter](https://serversideup.net/subscribe) - skip the algorithms and get quality content right to your inbox
* 🐥 [Twitter](https://twitter.com/serversideup) - you can also follow [Dan](https://twitter.com/danpastori) and [Jay](https://twitter.com/jaydrogers)
* ❤️ [Sponsor Us](https://github.com/sponsors/serversideup) - please consider sponsoring us so we can create more helpful resources

### Our Sponsors
All of our software is free an open to the world. None of this can be brought to you without the financial backing of our sponsors.
<p align="center">
		<a href="https://github.com/sponsors/serversideup"><img src="https://serversideup.net/wp-content/themes/serversideup/images/sponsor-empty-state.png" alt="Sponsors"></a>
</p>

# Available Docker Images
This is a list of the docker images this repository creates:

| ⚙️ Variation | ✨ Version | 🚀 Size |
|--------------|------------|------------|
| cli          | [7.4](https://hub.docker.com/r/serversideup/php/tags?name=7.4-cli&page=1&ordering=-name), [8.0](https://hub.docker.com/r/serversideup/php/tags?name=8.0-cli&page=1&ordering=-name), [8.1](https://hub.docker.com/r/serversideup/php/tags?name=8.1-cli&page=1&ordering=-name),  | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/serversideup/php/8.1-cli) |
| fpm          | [7.4](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm&page=1&ordering=-name), [8.0](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm&page=1&ordering=-name), [8.1](https://hub.docker.com/r/serversideup/php/tags?name=8.1-fpm&page=1&ordering=-name)  | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/serversideup/php/8.1-fpm) |
| fpm-apache   | [7.4](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm-apache&page=1&ordering=-name), [8.0](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm-apache&page=1&ordering=-name), [8.1](https://hub.docker.com/r/serversideup/php/tags?name=8.1-fpm-apache&page=1&ordering=-name)   | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/serversideup/php/8.1-fpm-apache) |
| fpm-nginx    | [7.4](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm-nginx&page=1&ordering=-name), [8.0](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm-nginx&page=1&ordering=-name), [8.1](https://hub.docker.com/r/serversideup/php/tags?name=8.1-fpm-nginx&page=1&ordering=-name)   |  ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/serversideup/php/8.1-fpm-nginx) |

### Usage
Simply use this image name pattern in any of your projects:
```sh
serversideup/php:{{version}}-{{variation-name}}
```
For example... If I wanted to run **PHP 8.0** with **FPM + NGINX**, I would use this image:
```sh
serversideup/php:8.0-fpm-nginx
```

### Real-life working example
You can see a bigger picture on how these images are used from Development to Production by viewing this video that shows a high level overview how we deploy "[ROAST](https://roastandbrew.coffee/)" which is a demo production app for [our book](https://serversideup.net/ultimate-guide-to-building-apis-and-spas-with-laravel-and-vuejs/).

Click the image below to view the video:

[![Laravel + NuxtJS From Dev to production](https://img.youtube.com/vi/PInGAWnvkjM/0.jpg)](https://www.youtube.com/watch?v=PInGAWnvkjM)

### Updates
✅ The image builds automatically run weekly (Tuesday at 0800 UTC) for latest security updates.

### How these images are built
All images are built off of the official Ubuntu 20.04 docker image. We first build our CLI image, then our FPM, etc. Here is what this looks like:

<img src="https://raw.githubusercontent.com/serversideup/docker-php/main/.github/dependency-diagram.png" alt="Dependency Diagram">

# Where do you host your stuff?
We get this question often. Our biggest principle is: **your infrastructure should be able to run anywhere.**

We believe privacy and control is the #1 priority when it comes to hosting infrastructure. We try to avoid the "big clouds" as much as possible because we're not comfortable that all 3 major players practice data mining of users and their products usually contain some sort of "vendor-lock".

We run all of our production servers on the latest LTS release of Ubuntu Server. The hosts we use are below. Some may be affiliate links that kick a few bucks at no extra cost to you, but they do not affect our recommendations at all. 

## [Vultr](https://vultr.grsm.io/create)
**Our current favorite.** Excellent performance and value. Lots of datacenter options too.

## [Digital Ocean](https://m.do.co/c/f3bad4b927ca)
Lots of developer love here. Not the best performing servers, but they do have a lot of awesome products!

## [Linode](https://www.linode.com/?r=5a1b585e4eb919d3d89ad242bd1bb2924754c444)
Great performance and great support. These guys have really enhanced their offering over the last few years.

### Benchmarks
If you're shopping for a host, [check out the benchmarks we've ran →](https://www.notion.so/521dimensions/Benchmark-Results-for-Self-hosted-Gitlab-Server-c6eca7c5f16d4bb8aeb989174fc58ffe)

### Can I run this on another host?
Sure! It all depends what platform you want to use, but if it supports Docker images, you likely can run it. These images are designed to give you freedom no matter where you want to run them.

# About this project
We're taking the extra effort to open source as much as we can. Not only could this potentially help someone learn a little bit of Docker, but it makes it a *heck of a lot* easier for us to work with you on new open source ideas.

### Project credits & inspiration

#### [Chris Fidao](https://github.com/fideloper)
Majority of our knowledge came from Chris' course, [Shipping Docker](https://serversforhackers.com/shipping-docker). If you have yet to discover his content, you will be very satisfied with every course he has to offer. He's a great human being and excellent educator.

#### [PHPDocker.io](https://github.com/phpdocker-io/base-images)
This team has an excellent repository and millions of pulls per month. We really like how they structured their code.

#### [linuxserver.io](https://www.linuxserver.io/)
These guys are absolute aces when it comes to Docker development. They are a great resource for tons of open source Docker images.

# Why these images and not other ones?
These images have a few key differences. These images are:

## 🚀 These images are used in production
Our philosophy is: **What you run in production is what you should be running in development.**

You'd be shocked how many people create a Docker image and use it in the local development only. These images are designed with the intention of being deployed to the open and wild Internet.

## 🔧 Optimized for Laravel and WordPress
We have a ton of helpful scripts and security settings configured for managing Laravel and WordPress.

### Automated tasks executed on every container start up
We automatically look at your Laravel `.env` file and determine if theses tasks should be run. 

If your `APP_ENV != local`(any environment other than local development), we will automatically run these repetitive tasks for you every time the container spins up:

**Database Migrations:**
```sh
php /var/www/html/artisan migrate --force
```
**Storage Linking:**
```sh
php /var/www/html/artisan storage:link
```


### Running a Laravel Task Scheduler
We need to run the [schedule:work](https://laravel.com/docs/8.x/scheduling#running-the-scheduler-locally) command from Laravel. Although the docs say "Running the scheduler locally", this is what we want in production. It will run the scheduler in the foreground and execute it every minute. You can configure your Laravel app for the exact time that a command should run through a [scheduled task](https://laravel.com/docs/8.x/scheduling#scheduling-artisan-commands).

**Task Scheduler Command:**
```sh
php /var/www/html/artisan schedule:work
```

**Example Docker Compose File:**
```yaml
version: '3'
services:
  php:
    image: my/laravel-app
    environment:
      PHP_POOL_NAME: "my-app_php"

  task:
    image: my/laravel-app
    command: "php /var/www/html/artisan schedule:work"
    environment:
      PHP_POOL_NAME: "my-app_task"
```

### Running a Laravel Queue
All you need to do is pass the Laravel Queue command to the container and S6 will automatically monitor it for you.

**Task Command:**
```sh
php /var/www/html/artisan queue:work --tries=3
```

**Example Docker Compose File:**
```yaml
version: '3'
services:
  php:
    image: my/laravel-app
    environment:
      PHP_POOL_NAME: "my-app_php"

  queue:
    image: my/laravel-app
    command: "php /var/www/html/artisan queue:work --tries=3"
    environment:
      PHP_POOL_NAME: "my-app_queue"
```

### Running Laravel Horizon with a Redis Queue 
By passing Laravel Horizon to our container, S6 will automatically monitor it.

**Horizon Command:**
```sh
php /var/www/html/artisan horizon
```

**Example Docker Compose File:**
```yaml
version: '3'
services:
  php:
    image: my/laravel-app
    environment:
      PHP_POOL_NAME: "my-app_php"

  redis:
    image: redis:6
    command: "redis-server --appendonly yes --requirepass redispassword"

  horizon:
    image: my/laravel-app
    command: "php /var/www/html/artisan horizon"
    environment:
      PHP_POOL_NAME: "my-app_horizon"
```

## 🔑 WordPress & Security Optimizations
* Hardening of Apache & NGINX included
* Disabling of XML-RPC
* Preventative access to sensitive version control or CI files
* Protection against other common attacks

See our [Apache security.conf](https://raw.githubusercontent.com/serversideup/docker-php/main/php/8.0/fpm-apache/etc/apache2/conf-available/security.conf) and [NGINX security.conf](https://raw.githubusercontent.com/serversideup/docker-php/main/php/8.0/fpm-nginx/etc/nginx/server-opts.d/security.conf) for more detail.

## 🧐 Based off of [S6 Overlay](https://github.com/just-containers/s6-overlay)
S6 Overlay is very helpful in managing a container's lifecycle that has multiple processes.

**Wait... Isn't Docker supposed to be a "single process per container"?** Yes, that's what it's like in a perfect world. Unfortunately PHP isn't like that. You need both a web server and a PHP-FPM server to see your files in order for your application to load.

We follow the [S6 Overlay Philosophy](https://github.com/just-containers/s6-overlay#the-docker-way) on how we can still get a single, disposable, and repeatable image of our application out to our servers.

# Environment Variables
We like to customize our images on a per app basis using environment variables. Look below to see what variables are available and what their defaults are. You can easily override them in your own docker environments ([see Docker's documentation](https://docs.docker.com/compose/environment-variables/#set-environment-variables-in-containers)).

**🔀 Variable Name**|**📚 Description**|**⚙️ Used in variation**|**#️⃣ Default Value**
:-----:|:-----:|:-----:|:-----:
PUID|User ID the webserver and PHP should run as.|all|9999
PGID|Group ID the webserver and PHP should run as.|all|9999
WEBUSER\_HOME|BETA: You can change the home of the web user if needed.|all (except *-nginx)|/var/www/html
PHP\_DATE\_TIMEZONE|Control your timezone. (<a href="https://www.php.net/manual/en/datetime.configuration.php#ini.date.timezone">Official Docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"UTC"
PHP\_DISPLAY\_ERRORS|Show PHP errors on screen. (<a href="https://www.php.net/manual/en/errorfunc.configuration.php#ini.display-errors">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|On
PHP\_ERROR\_REPORTING|Set PHP error reporting level. (<a href="https://www.php.net/manual/en/errorfunc.configuration.php#ini.error-reporting">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"E\_ALL & ~E\_DEPRECATED & ~E\_STRICT"
PHP\_MAX\_EXECUTION\_TIME|Set the maximum time in seconds a script is allowed to run before it is terminated by the parser. (<a href="https://www.php.net/manual/en/info.configuration.php#ini.max-execution-time">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"99"
PHP\_MEMORY\_LIMIT|Set the maximum amount of memory in bytes that a script is allowed to allocate. (<a href="https://www.php.net/manual/en/ini.core.php#ini.memory-limit">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"256M"
PHP\_PM\_CONTROL|Choose how the process manager will control the number of child processes. (<a href="https://www.php.net/manual/en/install.fpm.configuration.php">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|**fpm:** dynamic<br />**fpm-apache:** ondemand<br />**fpm-nginx:** ondemand
PHP\_PM\_MAX\_CHILDREN|The number of child processes to be created when pm is set to static and the maximum number of child processes to be created when pm is set to dynamic. (<a href="https://www.php.net/manual/en/install.fpm.configuration.php">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"20"
PHP\_PM\_MAX\_SPARE\_SERVERS|The desired maximum number of idle server processes. Used only when pm is set to dynamic. (<a href="https://www.php.net/manual/en/install.fpm.configuration.php">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"3"
PHP\_PM\_MIN\_SPARE\_SERVERS|The desired minimum number of idle server processes. Used only when pm is set to dynamic. (<a href="https://www.php.net/manual/en/install.fpm.configuration.php">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"1"
PHP\_PM\_START\_SERVERS|The number of child processes created on startup. Used only when pm is set to dynamic. (<a href="https://www.php.net/manual/en/install.fpm.configuration.php">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"2"
PHP\_POOL\_NAME|Set the name of your PHP-FPM pool (helpful when running multiple sites on a single server).|fpm,<br />fpm-nginx,<br />fpm-apache|"www"
PHP\_POST\_MAX\_SIZE|Sets max size of post data allowed. (<a href="https://www.php.net/manual/en/ini.core.php#ini.post-max-size">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"100M"
PHP\_UPLOAD\_MAX\_FILE\_SIZE|The maximum size of an uploaded file. (<a href="https://www.php.net/manual/en/ini.core.php#ini.upload-max-filesize">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"100M"
RUN\_LARAVEL\_AUTOMATIONS|Automatically run the Laravel Automations (for non-local Laravel installs only)|fpm,<br />fpm-nginx,<br />fpm-apache|"true"
MSMTP\_RELAY\_SERVER\_HOSTNAME|Server that should relay emails for MSMTP. (<a href="https://marlam.de/msmtp/msmtp.html">Official docs</a>)|fpm-nginx,<br />fpm-apache|"mailhog"<br /><br />🚨 IMPORTANT: Change this value if you want emails to work. (we set it to <a href="https://github.com/mailhog/MailHog">Mailhog</a> so our staging sites do not send emails out)
MSMTP\_RELAY\_SERVER\_PORT|Port the SMTP server is listening on. (<a href="https://marlam.de/msmtp/msmtp.html">Official docs</a>)|fpm-nginx,<br />fpm-apache|"1025" (default port for Mailhog)
DEBUG\_OUTPUT|Set this variable to `true` if you want to put PHP and your web server in debug mode.|fpm-nginx,<br />fpm-apache|(undefined, false)
APACHE\_DOCUMENT\_ROOT|Sets the directory from which Apache will serve files. (<a href="https://httpd.apache.org/docs/2.4/mod/core.html#documentroot">Official docs</a>)|fpm-apache|"/var/www/html"
APACHE\_MAX\_CONNECTIONS\_PER\_CHILD|Sets the limit on the number of connections that an individual child server process will handle.(<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#maxconnectionsperchild">Official docs</a>)|fpm-apache|"0"
APACHE\_MAX\_REQUEST\_WORKERS|Sets the limit on the number of simultaneous requests that will be served. (<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#maxrequestworkers">Official docs</a>)|fpm-apache|"150"
APACHE\_MAX\_SPARE\_THREADS|Maximum number of idle threads. (<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#maxsparethreads">Official docs</a>)|fpm-apache|"75"
APACHE\_MIN\_SPARE\_THREADS|Minimum number of idle threads to handle request spikes. (<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#minsparethreads">Official docs</a>)|fpm-apache|"10"
APACHE\_RUN\_GROUP|Set the username of what Apache should run as.|fpm-apache|"webgroup"
APACHE\_RUN\_USER|Set the username of what Apache should run as.|fpm-apache|"webuser"
APACHE\_START\_SERVERS|Sets the number of child server processes created on startup.(<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#startservers">Official docs</a>)|fpm-apache|"2"
APACHE\_THREAD\_LIMIT|Set the maximum configured value for ThreadsPerChild for the lifetime of the Apache httpd process. (<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#threadlimit">Official docs</a>)|fpm-apache|"64"
APACHE\_THREADS\_PER\_CHILD|This directive sets the number of threads created by each child process. (<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#threadsperchild">Official docs</a>)|fpm-apache|"25"

# Other customizations

### Installing additional PHP extensions
Let's say that we have a basic Docker compose image working in development:
```yaml
version: '3.7'
services:
  php:
    image: serversideup/php:8.0-fpm-nginx
    volumes:
      - .:/var/www/html/:cached
```
Now let's say we want to add the **PHP ImageMagick** extension. To do this, we will use the [docker compose build](https://docs.docker.com/compose/compose-file/compose-file-v3/#build) option in our YAML file.

This means we would need to change our file above to look like:
```yaml
version: '3.7'
services:
  php:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - .:/var/www/html/:cached
```

Notice the `services.php.build` options. We set a `.` to look for a dockerfile called `Dockerfile` within the same directory as our `docker-compose.yml` file.

For extra clarity, my project directory would look like this:
```txt
.
├── Dockerfile
├── docker-compose.yml
└── public
    └── index.php
```
The Dockerfile is where all the magic will happen. This is where we pull the Server Side Up image as a dependency, then run standard Ubuntu commands to add the extension that we need.

**Dockerfile:**
```Dockerfile
# Set our base image
FROM serversideup/php:8.0-fpm-nginx

# Install PHP Imagemagick using regular Ubuntu commands
RUN apt-get update \
    && apt-get install -y --no-install-recommends php8.0-imagick \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*
```

The next time you run `docker compose up`, Docker will build and cache the image for you automatically.

You can verify the CLI option installed correctly by echoing out the installed modules. Run this command in a new window **while your containers are running via Docker Compose**:

```sh
docker compose exec php php -m
```

To check that PHP-FPM loaded everything properly, use the [phpinfo()](https://www.php.net/manual/en/function.phpinfo.php) functionally.

#### ⚠️ Important note about caching
* You'll notice Docker likes to cache image builds (which is great for most functions)
* If you make changes to your *Dockerfile*, you may need to include `--build` with your Docker compose command ([read more here](https://docs.docker.com/compose/reference/up/))

If you want to rebuild, then you would run this:
```sh
docker compose up --build
```

#### How do I know which package name to use?
Refer to the official instructions of the extension that you are trying to install. We use Ondrej's PHP repository, so chances are you might be able to find in in here: https://launchpad.net/~ondrej/+archive/ubuntu/php/+packages

Make sure to use the same version number as well. For example... If you are using `8.0` and want to install the **php-imagick** package, use the name `php8.0-imagick` during install (see my examples above).

### Production SSL Configurations
You have a few options for running SSL. By default, we generate a self-signed certificate for simple local development. For production use, we recommend using [Traefik](https://traefik.io/) or [Caddy](https://caddyserver.com/) as a proxy to your actual container. This is what we do and it's really nice to use the automatic Let's Encrypt SSL management with these products.

If you really want you use your own provided certificate, you'll just need to use [Docker Volumes](https://docs.docker.com/storage/volumes/) and mount the `/etc/ssl/web` folder with these two files in that directory:

1. /etc/ssl/web/ssl.crt
1. /etc/ssl/web/ssl.key


# Submitting issues and pull requests
Since there are a lot of dependencies on these images, please understand that it can make it complicated on merging your pull request.

We'd love to have your help, but it might be best to explain your intentions first before contributing.

### Like we said -- we're always learning
If you find a critical security flaw, please open an issue or learn more about [our responsible disclosure policy](https://www.notion.so/Responsible-Disclosure-Policy-421a6a3be1714d388ebbadba7eebbdc8).
