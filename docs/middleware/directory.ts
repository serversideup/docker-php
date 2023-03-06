export default defineNuxtRouteMiddleware(( to, from ) => {
    switch( to.path ){
        case '/docs/getting-started':
            return navigateTo( to.path+'/these-images-vs-others', { replace: true } );
        break;
        case '/docs/guide':
            return navigateTo( to.path+'/choosing-the-right-image', { replace: true } );
        break;
    }
});