<template>
    <div class="w-full min-h-screen bg-black"></div>
</template>

<script setup>
const route = useRoute();

let redirectPath = route.path.endsWith('/') ? route.path.slice(0, -1) : route.path;

switch( redirectPath ){
    case '/docs/getting-started':
        navigateTo( redirectPath+'/these-images-vs-others', { replace: true } );
    break;
    case '/docs/guide':
        navigateTo( redirectPath+'/migrating-from-official-php-images', { replace: true } );
    break;
    case '/docs/reference':
        navigateTo( redirectPath+'/environment-variable-specification', { replace: true } );
    break;
    case '/docs/laravel':
        navigateTo( redirectPath+'/laravel-automations', { replace: true } );
    break;
    case '/docs/customizing-the-image':
        navigateTo( redirectPath+'/changing-common-php-settings', { replace: true } );
    break;
}
</script>