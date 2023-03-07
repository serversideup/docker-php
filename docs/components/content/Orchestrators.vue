<template>
    <div class="my-16 xl:max-w-none">
        <!-- <Heading level={2} id="official-orchestrators">
            Official orchestrators
        </Heading> -->
        <div class="not-prose mt-4 grid grid-cols-1 gap-x-6 gap-y-10 border-t pt-10 border-white/5 sm:grid-cols-2 xl:max-w-none xl:grid-cols-3">
            <div class="flex flex-row-reverse gap-6">
                <div class="flex-auto">
                    <h3 class="text-sm font-semibold text-white">
                        Docker
                    </h3>
                    <p class="mt-1 text-sm text-zinc-400">
                        Docker is a tool that enables users to deploy applications inside isolated containers for easy development and deployment.
                    </p>
                    <p class="mt-4">
                        <AppLink :href="'https://docs.docker.com/get-started/'"
                            :target="'_blank'"
                            :variant="'text'"
                            :arrow="'right'">
                                Read more
                        </AppLink>
                    </p>
                </div>
                <img
                    src="/images/logos/docker.svg"
                    alt=""
                    class="h-12 w-12"/>
            </div>
            <div class="flex flex-row-reverse gap-6">
                <div class="flex-auto">
                    <h3 class="text-sm font-semibold text-white">
                        Kubernetes
                    </h3>
                    <p class="mt-1 text-sm text-zinc-400">
                        Kubernetes is an open-source system for automating deployment, scaling, and management of containerized applications.
                    </p>
                    <p class="mt-4">
                        <AppLink :href="'https://kubernetes.io/docs/concepts/containers/images/'"
                            :target="'_blank'"
                            :variant="'text'"
                            :arrow="'right'">
                                Read more
                        </AppLink>
                    </p>
                </div>
                <img
                    src="/images/logos/kubernetes.svg"
                    alt=""
                    class="h-12 w-12"/>
            </div>
            <div class="flex flex-row-reverse gap-6">
                <div class="flex-auto">
                    <h3 class="text-sm font-semibold text-white">
                        HashiCorp Nomad
                    </h3>
                    <p class="mt-1 text-sm text-zinc-400">
                        HashiCorp Nomad is an open-source cluster scheduler that automates deployment, management & scaling of apps across public, private or hybrid clouds.
                    </p>
                    <p class="mt-4">
                        <AppLink :href="'https://developer.hashicorp.com/nomad/docs/drivers/docker'"
                            :target="'_blank'"
                            :variant="'text'"
                            :arrow="'right'">
                                Read more
                        </AppLink>
                    </p>
                </div>
                <img
                    src="/images/logos/nomad.svg"
                    alt=""
                    class="h-12 w-12"/>
            </div>
        </div>
    </div>
</template>