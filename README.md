<p align="center">
		<a href="https://serversideup.net/open-source/docker-php/"><img src="https://raw.githubusercontent.com/serversideup/docker-php/main/.github/img/header.png" width="1280" alt="Docker Images Logo"></a>
</p>
<p align="center">
	<a href="https://github.com/serversideup/docker-php/actions/workflows/publish_docker-images-production.yml"><img alt="Build Status" src="https://img.shields.io/github/actions/workflow/status/serversideup/docker-php/publish_docker-images-production.yml?branch=main"></a>
	<a href="https://github.com/serversideup/docker-php/blob/main/LICENSE" target="_blank"><img src="https://badgen.net/github/license/serversideup/docker-php" alt="License"></a>
	<a href="https://github.com/sponsors/serversideup"><img src="https://badgen.net/badge/icon/Support%20Us?label=GitHub%20Sponsors&color=orange" alt="Support us"></a>
  <br />
  <a href="https://hub.docker.com/r/serversideup/php/"><img alt="Docker Hub Pulls" src="https://img.shields.io/docker/pulls/serversideup/php"></a>
  <a href="https://serversideup.net/discord"><img alt="Discord" src="https://img.shields.io/discord/910287105714954251?color=blueviolet"></a>
</p>

## Introduction
`serversideup/php` is an optimized set of Docker Images for running PHP applications in production. Everything is designed around improving the developer experience with PHP and Docker. Gone are the days of configuring each environment differently, and gone are the days of trying to figure out why your code works in one environment and not the other.

These images are highly optimized to run modern PHP applications, no matter where you want your application to run.

Experience the ***true difference*** of using these images vs the other options out there.

[Read more about the key differences with these images →](https://serversideup.net/open-source/docker-php/docs/getting-started/these-images-vs-others)

<details open>
<summary>
 Features
</summary> <br />

|<picture><img width="100%" alt="Production-Ready" src="https://serversideup.net/wp-content/uploads/2023/08/production-ready.png"></picture>|<picture><img width="100%" alt="Native Health Checks" src="https://serversideup.net/wp-content/uploads/2023/08/native-health-checks.png"></picture>|<picture><img width="100%" alt="High Performance" src="https://serversideup.net/wp-content/uploads/2023/11/high-performance.png"></picture>|
|:---:|:---:|:---:|
|<picture><img width="100%" alt="Customizable and Flexible" src="https://serversideup.net/wp-content/uploads/2023/08/customizable-flexible.png"></picture>|<picture><img width="100%" alt="Native CloudFlare Support" src="https://serversideup.net/wp-content/uploads/2023/11/cloudflare.png"></picture>|<picture><img width="100%" alt="Base on Official PHP" src="https://serversideup.net/wp-content/uploads/2023/11/official-php.png"></picture>|
|<picture><img width="100%" alt="NGINX Unit" src="https://serversideup.net/wp-content/uploads/2023/11/nginx-unit.png"></picture>|<picture><img width="100%" alt="Unified Logging" src="https://serversideup.net/wp-content/uploads/2023/11/unified-logging.png"></picture>|<picture><img width="100%" alt="FPM + S6 Overlay" src="https://serversideup.net/wp-content/uploads/2023/11/fpm-s6.png"></picture>|

</details>

## Usage
This repository creates a number of Docker image variations, allowing you to choose exactly what you need.

Simply use this image name pattern in any of your projects:
```sh
serversideup/php:{{version}}-{{variation-name}}
```
For example... If I wanted to run **PHP 8.2** with **FPM + NGINX**, I would use this image:
```sh
serversideup/php:8.2-fpm-nginx
```

| ⚙️ Variation | 🚀 Version |
| ------------ | ---------- |
| cli          | [![serversideup/php:8.2-cli](https://img.shields.io/docker/image-size/serversideup/php/8.2-cli?label=serversideup%2Fphp%3A8.2-cli)](https://hub.docker.com/r/serversideup/php/tags?name=8.2-cli&page=1&ordering=-name)<br />[![serversideup/php:8.1-cli](https://img.shields.io/docker/image-size/serversideup/php/8.1-cli?label=serversideup%2Fphp%3A8.1-cli)](https://hub.docker.com/r/serversideup/php/tags?name=8.1-cli&page=1&ordering=-name)<br />[![serversideup/php:8.0-cli](https://img.shields.io/docker/image-size/serversideup/php/8.0-cli?label=serversideup%2Fphp%3A8.0-cli)](https://hub.docker.com/r/serversideup/php/tags?name=8.0-cli&page=1&ordering=-name)<br />[![serversideup/php:7.4-cli](https://img.shields.io/docker/image-size/serversideup/php/7.4-cli?label=serversideup%2Fphp%3A7.4-cli)](https://hub.docker.com/r/serversideup/php/tags?name=7.4-cli&page=1&ordering=-name) |
| fpm          | [![serversideup/php:8.2-fpm](https://img.shields.io/docker/image-size/serversideup/php/8.2-fpm?label=serversideup%2Fphp%3A8.2-fpm)](https://hub.docker.com/r/serversideup/php/tags?name=8.2-fpm&page=1&ordering=-name)<br />[![serversideup/php:8.1-fpm](https://img.shields.io/docker/image-size/serversideup/php/8.1-fpm?label=serversideup%2Fphp%3A8.1-fpm)](https://hub.docker.com/r/serversideup/php/tags?name=8.1-fpm&page=1&ordering=-name)<br />[![serversideup/php:8.0-fpm](https://img.shields.io/docker/image-size/serversideup/php/8.0-fpm?label=serversideup%2Fphp%3A8.0-fpm)](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm&page=1&ordering=-name)<br />[![serversideup/php:7.4-fpm](https://img.shields.io/docker/image-size/serversideup/php/7.4-fpm?label=serversideup%2Fphp%3A7.4-fpm)](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm&page=1&ordering=-name) |
| fpm-apache   | [![serversideup/php:8.2-fpm-apache](https://img.shields.io/docker/image-size/serversideup/php/8.2-fpm-apache?label=serversideup%2Fphp%3A8.2-fpm-apache)](https://hub.docker.com/r/serversideup/php/tags?name=8.2-fpm-apache&page=1&ordering=-name)<br />[![serversideup/php:8.1-fpm-apache](https://img.shields.io/docker/image-size/serversideup/php/8.1-fpm-apache?label=serversideup%2Fphp%3A8.1-fpm-apache)](https://hub.docker.com/r/serversideup/php/tags?name=8.1-fpm-apache&page=1&ordering=-name)<br />[![serversideup/php:8.0-fpm-apache](https://img.shields.io/docker/image-size/serversideup/php/8.0-fpm-apache?label=serversideup%2Fphp%3A8.0-fpm-apache)](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm-apache&page=1&ordering=-name)<br />[![serversideup/php:7.4-fpm-apache](https://img.shields.io/docker/image-size/serversideup/php/7.4-fpm-apache?label=serversideup%2Fphp%3A7.4-fpm-apache)](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm-apache&page=1&ordering=-name) |
| fpm-nginx    | [![serversideup/php:8.2-fpm-nginx](https://img.shields.io/docker/image-size/serversideup/php/8.2-fpm-nginx?label=serversideup%2Fphp%3A8.2-fpm-nginx)](https://hub.docker.com/r/serversideup/php/tags?name=8.2-fpm-nginx&page=1&ordering=-name)<br />[![serversideup/php:8.1-fpm-nginx](https://img.shields.io/docker/image-size/serversideup/php/8.1-fpm-nginx?label=serversideup%2Fphp%3A8.1-fpm-nginx)](https://hub.docker.com/r/serversideup/php/tags?name=8.1-fpm-nginx&page=1&ordering=-name)<br />[![serversideup/php:8.0-fpm-nginx](https://img.shields.io/docker/image-size/serversideup/php/8.0-fpm-nginx?label=serversideup%2Fphp%3A8.0-fpm-nginx)](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm-nginx&page=1&ordering=-name)<br />[![serversideup/php:7.4-fpm-nginx](https://img.shields.io/docker/image-size/serversideup/php/7.4-fpm-nginx?label=serversideup%2Fphp%3A7.4-fpm-nginx)](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm-nginx&page=1&ordering=-name) |

### Real-life working example
You can see a bigger picture on how these images are used from Development to Production by viewing this video that shows a high level overview how we deploy "[ROAST](https://roastandbrew.coffee/)" which is a demo production app for [our book](https://serversideup.net/ultimate-guide-to-building-apis-and-spas-with-laravel-and-vuejs/).

Click the image below to view the video:

[![Laravel + NuxtJS From Dev to production](https://img.youtube.com/vi/PInGAWnvkjM/0.jpg)](https://www.youtube.com/watch?v=PInGAWnvkjM)

## Resources
- **[Website](https://serversideup.net/open-source/docker-php/)** overview of the product.
- **[Docs](https://serversideup.net/open-source/docker-php/docs)** for a deep-dive on how to use the product.
- **[Discord](https://serversideup.net/discord)** for friendly support from the community and the team.
- **[GitHub](https://github.com/serversideup/docker-php)** for source code, bug reports, and project management.
- **[Get Professional Help](https://serversideup.net/professional-support)** - Get video + screen-sharing help directly from the core contributors.

## Contributing
As an open-source project, we strive for transparency and collaboration in our development process. We greatly appreciate any contributions members of our community can provide. Whether you're fixing bugs, proposing features, improving documentation, or spreading awareness - your involvement strengthens the project. Please review our [contribution guidelines](https://serversideup.net/open-source/docker-php/docs/getting-started/contributing) and [code of conduct](./.github/code_of_conduct.md) to understand how we work together respectfully.

- **Bug Report**: If you're experiencing an issue while using these images, please [create an issue](https://github.com/serversideup/docker-php/issues/new/choose).
- **Feature Request**: Make this project better by [submitting a feature request](https://github.com/serversideup/docker-php/discussions/66).
- **Documentation**: Improve our documentation by [submitting a documentation change](./docs/README.md).
- **Community Support**: Help others on [GitHub Discussions](https://github.com/serversideup/docker-php/discussions) or [Discord](https://serversideup.net/discord).
- **Security Report**: Report critical security issues via [our responsible disclosure policy](https://www.notion.so/Responsible-Disclosure-Policy-421a6a3be1714d388ebbadba7eebbdc8).

Need help getting started? Join our Discord community and we'll help you out!

<a href="https://serversideup.net/discord"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/join-discord.svg" title="Join Discord"></a>

## Our Sponsors
All of our software is free an open to the world. None of this can be brought to you without the financial backing of our sponsors.

<p align="center"><a href="https://github.com/sponsors/serversideup"><img src="https://521public.s3.amazonaws.com/serversideup/sponsors/sponsor-box.png" alt="Sponsors"></a></p>

#### Individual Supporters
<!-- supporters --><a href="https://github.com/alexjustesen"><img src="https://github.com/alexjustesen.png" width="40px" alt="alexjustesen" /></a>&nbsp;&nbsp;<a href="https://github.com/GeekDougle"><img src="https://github.com/GeekDougle.png" width="40px" alt="GeekDougle" /></a>&nbsp;&nbsp;<!-- supporters -->

#### Special thanks
We'd like to specifically thank a few folks for taking the time for being a sound board that deeply influenced the direction of this project.

Please check out all of their work:
- [Chris Fidao](https://twitter.com/fideloper)
- [Joel Clermont](https://twitter.com/joelclermont)
- [Patricio](https://twitter.com/PatricioOnCode)

## About Us
We're [Dan](https://twitter.com/danpastori) and [Jay](https://twitter.com/jaydrogers) - a two person team with a passion for open source products. We created [Server Side Up](https://serversideup.net) to help share what we learn.

<div align="center">

| <div align="center">Dan Pastori</div>                  | <div align="center">Jay Rogers</div>                                 |
| ----------------------------- | ------------------------------------------ |
| <div align="center"><a href="https://twitter.com/danpastori"><img src="https://serversideup.net/wp-content/uploads/2023/08/dan.jpg" title="Dan Pastori" width="150px"></a><br /><a href="https://twitter.com/danpastori"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/twitter.svg" title="Twitter" width="24px"></a><a href="https://github.com/danpastori"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/github.svg" title="GitHub" width="24px"></a></div>                        | <div align="center"><a href="https://twitter.com/jaydrogers"><img src="https://serversideup.net/wp-content/uploads/2023/08/jay.jpg" title="Jay Rogers" width="150px"></a><br /><a href="https://twitter.com/jaydrogers"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/twitter.svg" title="Twitter" width="24px"></a><a href="https://github.com/jaydrogers"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/github.svg" title="GitHub" width="24px"></a></div>                                       |

</div>

### Find us at:

* **📖 [Blog](https://serversideup.net)** - Get the latest guides and free courses on all things web/mobile development.
* **🙋 [Community](https://community.serversideup.net)** - Get friendly help from our community members.
* **🤵‍♂️ [Get Professional Help](https://serversideup.net/professional-support)** - Get video + screen-sharing support from the core contributors.
* **💻 [GitHub](https://github.com/serversideup)** - Check out our other open source projects.
* **📫 [Newsletter](https://serversideup.net/subscribe)** - Skip the algorithms and get quality content right to your inbox.
* **🐥 [Twitter](https://twitter.com/serversideup)** - You can also follow [Dan](https://twitter.com/danpastori) and [Jay](https://twitter.com/jaydrogers).
* **❤️ [Sponsor Us](https://github.com/sponsors/serversideup)** - Please consider sponsoring us so we can create more helpful resources.

## Our products
If you appreciate this project, be sure to check out our other projects.

### 📚 Books
- **[The Ultimate Guide to Building APIs & SPAs](https://serversideup.net/ultimate-guide-to-building-apis-and-spas-with-laravel-and-nuxt3/)**: Build web & mobile apps from the same codebase.
- **[Building Multi-Platform Browser Extensions](https://serversideup.net/building-multi-platform-browser-extensions/)**: Ship extensions to all browsers from the same codebase.

### 🛠️ Software-as-a-Service
- **[Bugflow](https://bugflow.io/)**: Get visual bug reports directly in GitHub, GitLab, and more.
- **[SelfHost Pro](https://selfhostpro.com/)**: Connect Stripe or Lemonsqueezy to a private docker registry for self-hosted apps.

### 🌍 Open Source
- **[AmplitudeJS](https://521dimensions.com/open-source/amplitudejs)**: Open-source HTML5 & JavaScript Web Audio Library.
- **[Spin](https://serversideup.net/open-source/spin/)**: Laravel Sail alternative for running Docker from development → production.
- **[Financial Freedom](https://github.com/serversideup/financial-freedom)**: Open source alternative to Mint, YNAB, & Monarch Money.