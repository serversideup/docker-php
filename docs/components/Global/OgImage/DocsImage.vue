<script setup>
// inherited attrs can mess up the satori parser
defineOptions({
    inheritAttrs: false,
})

const props = defineProps({
    title: {
        type: String,
        default: '',
    },
    description: {
        type: String,
        default: '',
    }
})
</script>

<template>
    <div class="w-full h-full bg-black border-blue-700 border-solid border-[12px] relative">
        <div style="position: absolute; left: 0px; top: 0px; bottom: 0px; width: 852px; padding-left: 24px; padding-right: 48px;">
            <div style="display: flex; flex-direction: column; justify-content: center; height: 606px;">
                <span class="text-white font-sans text-8xl font-bold" v-text="title"></span>
                <span class="text-gray-400 font-sans text-3xl font-normal" v-text="description"></span>
            </div>
        </div>
        
        <div style="position: absolute; right: 0px; top: 0px; bottom: 0px; width: 323px">
            <img style="position: absolute; right: 30px; top: 120px;" src="/images/logos/og-logo.png"/>
            <img style="position: absolute; right: 10px; bottom: 0px" src="/images/logos/og-ssu-logo.png"/>
        </div>
    </div>
</template>