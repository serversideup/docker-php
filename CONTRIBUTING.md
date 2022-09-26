# Contribution guide
Thanks for your interest in contributing to this project!

As stated in the README, there are a lot of down-stream dependencies on these images, so please understand that it can make it complicated on merging your pull request.

We'd love to have your help, but it might be best to explain your intentions first before contributing.

# Project dependencies
You must have these installed on your system.
* Docker (container system): https://www.docker.com/products/docker-desktop

# How things work
1. All files are stored in the `/src` folder
1. Github Actions will automatically build and deploy the images

# Running things locally

To run a build, simply run `./dev.sh` (with Docker Desktop Running). This will automatically build the beta images on your local machine. If you want to only build a specific version, you pass it a version you want to build (example: `./dev.sh 8.1`)

#### Viewing the images
After running the build, you should be able to run `docker images` to see all available images on your machine. Everything built with `./dev.sh` will be tagged `serversideup/php:beta-*`.

#### Running a test web server:
This is helpful for testing things out:
```sh
docker run --rm -v $(pwd):/var/www/html -p 80:80 -p 443:443 serversideup/php:beta-8.1-fpm-nginx
```