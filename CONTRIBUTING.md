# Contribution guide
Thanks for your interest in contributing to this project!

As stated in the README, there are a lot of dependencies on these images, so please understand that it can make it complicated on merging your pull request.

We'd love to have your help, but it might be best to explain your intentions first before contributing.

# Project dependencies
You must have these installed on your system.
* Docker (container system): https://www.docker.com/products/docker-desktop
* Yasha (templating engine): https://github.com/kblomqvist/yasha

# How things work
1. All templates are stored in the `/src` folder
1. I have a Git "Pre-Commit" hook that runs `build.sh`
1. `build.sh` copies the templates and applies the templates with [yasha](https://github.com/kblomqvist/yasha)
1. All generated files are then stored in the `/dist` folder
1. Github Actions will read the generated files and build images from the generated files

# Running things locally

To run a build, simply run `./dev.sh`. This will automatically build the beta images on your local machine.

#### Viewing the images
After running the build, you should be able to run `docker images` to see all available images on your machine. Everything built with `./dev.sh` will be tagged `serversideup/php:beta-*`.

#### Running a test web server:
This is helpful for testing things out:
```sh
docker run --rm -v $(pwd):/var/www/html -p 80:80 -p 443:443 serversideup/php:beta-8.1-fpm-nginx
```