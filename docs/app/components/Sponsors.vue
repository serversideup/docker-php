<template>
    <div class="mx-auto py-8 md:py-16 flex flex-col w-full">
        <h4 class="mb-2 font-medium text-white font-sans">Platinum Sponsors</h4>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-y-4 md:gap-y-0 gap-x-2">
            <NuxtLink to="https://sevalla.com/" target="_blank" class="p-[10px] rounded bg-[#13161B] hover:bg-[#22262F] h-32 flex items-center justify-center transition-all duration-200">
                <img src="/assets/icons/hosts/sevalla.svg" alt="Sponsor" class="w-64 md:w-full object-contain" />
            </NuxtLink>

            <NuxtLink target="_blank" to="https://github.com/sponsors/serversideup" class="p-[10px] rounded bg-[#13161B] h-32 flex items-center justify-center text-[#94979C] font-medium font-sans hover:bg-[#22262F] transition-all duration-200">
                Become a Sponsor
            </NuxtLink>

            <div class="hidden md:flex p-[10px] rounded bg-[#13161B] h-32 items-center justify-center text-[#94979C] font-medium font-sans">
                
            </div>
        </div>
    </div>
</template>