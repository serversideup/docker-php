<template>
    <div class="mx-auto max-w-[940px] flex flex-col py-8 px-6 lg:py-16">
        <h2 class="font-inter text-[28px] leading-[32px] text-white text-center font-bold mb-16 lg:text-5xl lg:leading-[48px]">
            What others are saying
        </h2>

        <div class="grid grid-cols-1 gap-[10px] md:grid-cols-2 lg:grid-cols-3">
            <div class="p-[10px] flex flex-col items-center">
                <img src="/images/testimonials/chris-fidao.png" class="rounded-full mb-1 w-[50px]"/>
                <span class="font-inter font-bold leading-6 text-2xl text-white">Chris Fidao</span>
                <span class="text-slate-300 font-inter text-base">Creator of <NuxtLink class="underline" href="https://serversforhackers.com/" target="_blank">Servers for Hackers</NuxtLink></span>
                <p class="font-inter font-normal text-base text-slate-50 mt-2">
                    Today I'm appreciating the work
                    @jaydrogers (& others!) put into these base PHP containers.
                    <br><br>
                    The official PHP images are...sort of ridiculous.
                </p>
            </div>
            <div class="p-[10px] flex flex-col items-center">
                <img src="/images/testimonials/johan-janssens.png" class="rounded-full mb-1 w-[50px]"/>
                <span class="font-inter font-bold leading-6 text-2xl text-white">Johan Janssens</span>
                <span class="text-slate-300 font-inter text-base">Co-Founder of <NuxtLink href="https://www.joomla.org/" target="_blank" class="underline">Joomla</NuxtLink></span>
                <p class="font-inter font-normal text-base text-slate-50 mt-2">
                    Used the excellent Docker-PHP images from @jaydrogers.  Demo'ed how to handle 10k async HTTP requests in 3secs, all using nothing else then PHP using OpenSwoole and supervised to perfection with S6. 
                    <br><br>
                    For a PHP dev, that should not be possible... look on people's face ...priceless!
                </p>
            </div>
            <div class="p-[10px] flex flex-col items-center">
                <img src="/images/testimonials/ziga-zajc.png" class="rounded-full mb-1 w-[50px]"/>
                <span class="font-inter font-bold leading-6 text-2xl text-white">Žiga Zajc</span>
                <span class="text-slate-300 font-inter text-base">CEO of <NuxtLink href="https://rabbit-company.com/" target="_blank" class="underline">Rabbit Company</NuxtLink></span>
                <p class="font-inter font-normal text-base text-slate-50 mt-2">
                    Based on our performance testing, the PHP-FPM image by Server Side Up has the capability to manage 484 requests per second without any project limitations. In comparison, the official PHP image is only able to handle 68 requests per second.
                </p>
            </div>
        </div>
    </div>
</template>