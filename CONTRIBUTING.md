# Contribution guide
Thanks for your interest in contributing to this project!

As stated in the README, there are a lot of dependencies on these images, so please understand that it can make it complicated on merging your pull request.

We'd love to have your help, but it might be best to explain your intentions first before contributing.

# Project dependencies
You must have these installed on your system.
* Docker (container system): https://www.docker.com/products/docker-desktop
* Yasha (templating engine): https://github.com/kblomqvist/yasha

# How things work
1. All templates are stored in the `/templates` folder
1. I have a Git "Pre-Commit" hook that runs `build.sh`
1. `build.sh` copies the templates and applies the templates with [yasha](https://github.com/kblomqvist/yasha)
1. All generated files are then stored in the `/php` folder
1. Github Actions will read the generated files and build images from the generated files

# Running things locally
Run this command to bring up a temporary local registry at `localhost:500` (Press `CTRL+C` to exit):
```sh
docker run --rm -p 5000:5000 --name registry registry:2
```
This will create a temporary local registry that we can now use for testing Dockerfiles locally, for example:
```Dockerfile
FROM localhost:5000/php:8.0-cli

CMD php -v
```

I can also inspect the image by running 
```sh
docker run --rm -it localhost:5000/php:8.0-cli bash
```