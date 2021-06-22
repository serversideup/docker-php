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
We like to customize our images on a per app basis using environment variables. Look below to see what variables are available and what their defaults are. You can easily override them in your own docker environments ([see Docker's documentation](https://docs.docker.com/compose/environment-variables/#set-environment-variables-in-containers)).

**🔀 Variable Name**|**📚 Description**|**⚙️ Used in variation**|**#️⃣ Default Value**
:-----:|:-----:|:-----:|:-----:
PHP\_DATE\_TIMEZONE|Control your timezone. (<a href="https://www.php.net/manual/en/datetime.configuration.php#ini.date.timezone">Official Docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"UTC"
PHP\_DISPLAY\_ERRORS|Show PHP errors on screen. (<a href="https://www.php.net/manual/en/errorfunc.configuration.php#ini.display-errors">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|On
PHP\_ERROR\_REPORTING|Set PHP error reporting level. (<a href="https://www.php.net/manual/en/errorfunc.configuration.php#ini.error-reporting">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"E\_ALL & ~E\_DEPRECATED & ~E\_STRICT"
PHP\_MEMORY\_LIMIT|Set the maximum amount of memory in bytes that a script is allowed to allocate. (<a href="https://www.php.net/manual/en/ini.core.php#ini.memory-limit">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"256M"
PHP\_MAX\_EXECUTION\_TIME|Set the maximum time in seconds a script is allowed to run before it is terminated by the parser. (<a href="https://www.php.net/manual/en/info.configuration.php#ini.max-execution-time">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"99"
PHP\_POST\_MAX\_SIZE|Sets max size of post data allowed. (<a href="https://www.php.net/manual/en/ini.core.php#ini.post-max-size">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"100M"
PHP\_UPLOAD\_MAX\_FILE\_SIZE|The maximum size of an uploaded file. (<a href="https://www.php.net/manual/en/ini.core.php#ini.upload-max-filesize">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"100M"
PHP\_POOL\_NAME|Set the name of your PHP-FPM pool (helpful when running multiple sites on a single server).|fpm,<br />fpm-nginx,<br />fpm-apache|"www"
PHP\_PM\_CONTROL|Choose how the process manager will control the number of child processes. (<a href="https://www.php.net/manual/en/install.fpm.configuration.php">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|**fpm:** dynamic<br />**fpm-apache:** ondemand<br />**fpm-nginx:** ondemand
PHP\_PM\_MAX\_CHILDREN|The number of child processes to be created when pm is set to static and the maximum number of child processes to be created when pm is set to dynamic. (<a href="https://www.php.net/manual/en/install.fpm.configuration.php">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"20"
PHP\_PM\_START\_SERVERS|The number of child processes created on startup. Used only when pm is set to dynamic. (<a href="https://www.php.net/manual/en/install.fpm.configuration.php">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"2"
PHP\_PM\_MIN\_SPARE\_SERVERS|The desired minimum number of idle server processes. Used only when pm is set to dynamic. (<a href="https://www.php.net/manual/en/install.fpm.configuration.php">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"1"
PHP\_PM\_MAX\_SPARE\_SERVERS|The desired maximum number of idle server processes. Used only when pm is set to dynamic. (<a href="https://www.php.net/manual/en/install.fpm.configuration.php">Official docs</a>)|fpm,<br />fpm-nginx,<br />fpm-apache|"3"
MSMTP\_RELAY\_SERVER\_HOSTNAME|Server that should relay emails for MSMTP. (<a href="https://marlam.de/msmtp/msmtp.html">Official docs</a>)|fpm-nginx,<br />fpm-apache|"mailhog" (we set it to <a href="https://github.com/mailhog/MailHog">Mailhog</a> so our staging sites do not send emails out)
MSMTP\_RELAY\_SERVER\_PORT|Port the SMTP server is listening on. (<a href="https://marlam.de/msmtp/msmtp.html">Official docs</a>)|fpm-nginx,<br />fpm-apache|"1025" (default port for Mailhog)
APACHE\_START\_SERVERS|Sets the number of child server processes created on startup.(<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#startservers">Official docs</a>)|fpm-apache|"2"
APACHE\_MIN\_SPARE\_THREADS|Minimum number of idle threads to handle request spikes. (<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#minsparethreads">Official docs</a>)|fpm-apache|"10"
APACHE\_MAX\_SPARE\_THREADS|Maximum number of idle threads. (<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#maxsparethreads">Official docs</a>)|fpm-apache|"75"
APACHE\_THREAD\_LIMIT|Set the maximum configured value for ThreadsPerChild for the lifetime of the Apache httpd process. (<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#threadlimit">Official docs</a>)|fpm-apache|"64"
APACHE\_THREADS\_PER\_CHILD|This directive sets the number of threads created by each child process. (<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#threadsperchild">Official docs</a>)|fpm-apache|"25"
APACHE\_MAX\_REQUEST\_WORKERS|Sets the limit on the number of simultaneous requests that will be served. (<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#maxrequestworkers">Official docs</a>)|fpm-apache|"150"
APACHE\_MAX\_CONNECTIONS\_PER\_CHILD|Sets the limit on the number of connections that an individual child server process will handle.(<a href="https://httpd.apache.org/docs/2.4/mod/mpm\_common.html#maxconnectionsperchild">Official docs</a>)|fpm-apache|"0"
APACHE\_RUN\_USER|Set the username of what Apache should run as.|fpm-apache|"www-data"
APACHE\_RUN\_GROUP|Set the username of what Apache should run as.|fpm-apache|"www-data"
APACHE\_DOCUMENT\_ROOT|Sets the directory from which Apache will serve files. (<a href="https://httpd.apache.org/docs/2.4/mod/core.html#documentroot">Official docs</a>)|fpm-apache|"/var/www/html"

# Submitting issues and pull requests
Since there are a lot of dependencies on these images, please understand that it can make it complicated on mergine your pull request.

We'd love to have your help, but it might be best to explain your intentions first before contributing.

### Like we said -- we're always learning
If you find a critical security flaw, please open an issue or learn more about [our responsible disclosure policy](https://www.notion.so/Responsible-Disclosure-Policy-421a6a3be1714d388ebbadba7eebbdc8).
