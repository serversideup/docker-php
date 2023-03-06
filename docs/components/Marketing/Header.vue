<template>
    <div class="w-full">
    <header class="w-full py-4 px-6 backdrop-blur z-50 lg:px-8" :class="{ 'fixed top-[43px]': fixed }">
        <div class="flex items-center justify-between">
            <NuxtLink :to="'/'">
                <img class="w-52 xl:w-72" src="/images/logos/php-docker-logo.svg"/>
            </NuxtLink>

            <div class="flex items-center">
                <AlgoliaDocSearch class="mr-4"/>

                <div class="flex items-center lg:hidden">
                    <button @click="toggleMobileNav()" class="flex items-center justify-center w-6 h-6 cursor-pointer">
                        <div id="nav-icon" class="w-[18px] h-3 relative" :class="{
                            'open': showMobileMenu
                        }">
                            <span></span>
                            <span></span>
                            <span></span>
                            <span></span>
                            <span></span>
                            <span></span>
                        </div>
                    </button>
                </div>
                <nav class="items-center hidden lg:flex">
                    <div class="flex items-center gap-4 lg:gap-4 xl:gap-8 mr-8">
                        <NuxtLink 
                            :href="'/docs'"
                            class="flex items-center font-inter font-bold text-slate-300 text-sm rounded py-[6px] px-2 hover:bg-gray-900 xl:text-lg">
                                <div class="flex items-center justify-center w-5 h-5 mr-2">
                                    <svg width="18" height="23" viewBox="0 0 18 23" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-full max-h-full">
                                        <path d="M17 18.4468V15.4468H4C2.34315 15.4468 1 16.79 1 18.4468M5.8 21.4468H13.8C14.9201 21.4468 15.4802 21.4468 15.908 21.2289C16.2843 21.0371 16.5903 20.7311 16.782 20.3548C17 19.927 17 19.3669 17 18.2468V4.64684C17 3.52673 17 2.96668 16.782 2.53886C16.5903 2.16253 16.2843 1.85657 15.908 1.66483C15.4802 1.44684 14.9201 1.44684 13.8 1.44684H5.8C4.11984 1.44684 3.27976 1.44684 2.63803 1.77382C2.07354 2.06144 1.6146 2.52038 1.32698 3.08487C1 3.7266 1 4.56668 1 6.24684V16.6468C1 18.327 1 19.1671 1.32698 19.8088C1.6146 20.3733 2.07354 20.8322 2.63803 21.1199C3.27976 21.4468 4.11984 21.4468 5.8 21.4468Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                                    </svg>
                                </div>
                                
                                Docs
                        </NuxtLink>  
                        
                        <NuxtLink 
                            :href="'https://community.serversideup.net/'"
                            target="_blank"
                            class="flex items-center font-inter font-bold text-slate-300 text-sm rounded py-[6px] px-2 hover:bg-gray-900 xl:text-lg">
                                <div class="flex items-center justify-center w-5 h-5 mr-2">
                                    <svg width="22" height="20" viewBox="0 0 22 20" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-full max-h-full">
                                        <path d="M15 1.9146C16.4817 2.65095 17.5 4.17998 17.5 5.94684C17.5 7.7137 16.4817 9.24273 15 9.97908M17 15.2132C18.5115 15.8972 19.8725 17.0118 21 18.4468M1 18.4468C2.94649 15.9694 5.58918 14.4468 8.5 14.4468C11.4108 14.4468 14.0535 15.9694 16 18.4468M13 5.94684C13 8.43212 10.9853 10.4468 8.5 10.4468C6.01472 10.4468 4 8.43212 4 5.94684C4 3.46156 6.01472 1.44684 8.5 1.44684C10.9853 1.44684 13 3.46156 13 5.94684Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                                    </svg>
                                </div>
                                
                                Community
                        </NuxtLink>  

                        <NuxtLink 
                            :href="'https://github.com/serversideup/docker-php'"
                            target="_blank"
                            class="flex items-center font-inter font-bold text-slate-300 text-sm rounded py-[6px] px-2 hover:bg-gray-900 xl:text-lg">
                                <div class="flex items-center justify-center w-5 h-5 mr-2">
                                    <svg width="20" height="22" viewBox="0 0 14 15" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-full max-h-full">
                                        <path d="M7 0.65799C3.1325 0.65799 0 3.79049 0 7.65799C0 10.7555 2.00375 13.3717 4.78625 14.2992C5.13625 14.3605 5.2675 14.1505 5.2675 13.9667C5.2675 13.8005 5.25875 13.2492 5.25875 12.663C3.5 12.9867 3.045 12.2342 2.905 11.8405C2.82625 11.6392 2.485 11.018 2.1875 10.8517C1.9425 10.7205 1.5925 10.3967 2.17875 10.388C2.73 10.3792 3.12375 10.8955 3.255 11.1055C3.885 12.1642 4.89125 11.8667 5.29375 11.683C5.355 11.228 5.53875 10.9217 5.74 10.7467C4.1825 10.5717 2.555 9.96799 2.555 7.29049C2.555 6.52924 2.82625 5.89924 3.2725 5.40924C3.2025 5.23424 2.9575 4.51674 3.3425 3.55424C3.3425 3.55424 3.92875 3.37049 5.2675 4.27174C5.8275 4.11424 6.4225 4.03549 7.0175 4.03549C7.6125 4.03549 8.2075 4.11424 8.7675 4.27174C10.1063 3.36174 10.6925 3.55424 10.6925 3.55424C11.0775 4.51674 10.8325 5.23424 10.7625 5.40924C11.2087 5.89924 11.48 6.52049 11.48 7.29049C11.48 9.97674 9.84375 10.5717 8.28625 10.7467C8.54 10.9655 8.75875 11.3855 8.75875 12.0417C8.75875 12.978 8.75 13.7305 8.75 13.9667C8.75 14.1505 8.88125 14.3692 9.23125 14.2992C10.6209 13.8301 11.8284 12.937 12.6839 11.7457C13.5393 10.5543 13.9996 9.12467 14 7.65799C14 3.79049 10.8675 0.65799 7 0.65799Z" fill="currentColor"/>
                                    </svg>
                                </div>
                                
                                Github
                        </NuxtLink>  

                        <NuxtLink target="_blank" :to="'https://github.com/sponsors/serversideup'" class="flex items-center px-[14px] py-2 font-bold font-inter text-white rounded-lg border border-solid border-slate-700 bg-slate-800 hover:bg-slate-700 text-sm">
                            Sponsor
                            <img class="ml-[10px]" src="/images/icons/heart.svg"/>
                        </NuxtLink>

                        <NuxtLink :to="'/docs'" class="flex items-center px-[14px] py-2 font-bold font-inter text-white rounded-lg bg-blue-600 text-sm hover:bg-blue-500">
                            Get Started &rarr;
                        </NuxtLink>
                    </div>
                </nav>
            </div>
        </div>
    </header>
    <GlobalMobileMenu
        :show="showMobileMenu"
        :navigation="navigation"/>
</div>
</template>

<script setup>
const props = defineProps({ 
    navigation: {
        default(){
            return []
        }
    },
    fixed: {
        default: false
    }
});
const showMobileMenu = ref(false);

const toggleMobileNav = () => {
    showMobileMenu.value = showMobileMenu.value ? false : true;
}

watch(showMobileMenu, ( newValue ) => {
    if( newValue ){
        document.documentElement.classList.add('overflow-y-hidden');
        document.body.classList.add('overflow-y-hidden');
    }else{
        document.documentElement.classList.remove('overflow-y-hidden');
        document.body.classList.remove('overflow-y-hidden');
    }
});
</script>