#!/bin/sh
if [ "$LOG_LEVEL" = "debug" ]; then
  set -x
fi

# Exit on error
set -e

# Check to see if an Artisan file exists and assume it means Laravel is configured.
if [ -f $APP_BASE_DIR/artisan ] && [ ${AUTORUN_ENABLED:="true"} == "true" ]; then
        echo "Checking for Laravel automations..."

        ############################################################################
        # artisan config:cache
        ############################################################################
        if [ ${AUTORUN_LARAVEL_CONFIG_CACHE:="true"} == "true" ]; then
            echo "🚀 Caching Laravel config..."
            php $APP_BASE_DIR/artisan config:cache
        fi

        ############################################################################
        # artisan route:cache
        ############################################################################
        if [ ${AUTORUN_LARAVEL_ROUTE_CACHE:="true"} == "true" ]; then
            echo "🚀 Caching Laravel routes..."
            php $APP_BASE_DIR/artisan route:cache
        fi

        ############################################################################
        # artisan view:cache
        ############################################################################
        if [ ${AUTORUN_LARAVEL_VIEW_CACHE:="true"} == "true" ]; then
            echo "🚀 Caching Laravel views..."
            php $APP_BASE_DIR/artisan view:cache
        fi

        ############################################################################
        # artisan event:cache
        ###########################################################################
        if [ ${AUTORUN_LARAVEL_EVENT_CACHE:="true"} == "true" ]; then
            echo "🚀 Caching Laravel events..."
            php $APP_BASE_DIR/artisan event:cache
        fi
        
        ############################################################################
        # artisan migrate
        ############################################################################
        if [ ${AUTORUN_LARAVEL_MIGRATION:="false"} == "true" ]; then
            echo "🚀 Running migrations..."
            php $APP_BASE_DIR/artisan migrate --force --isolated
        fi

        ############################################################################
        # Automated storage linking
        ############################################################################
        if [ ${AUTORUN_LARAVEL_STORAGE_LINK:="true"} == "true" ]; then
            if [ -d $APP_BASE_DIR/public/storage ]; then
                echo "✅ Storage already linked..."
            else
                echo "🔐 Linking the storage..."
                php $APP_BASE_DIR/artisan storage:link
            fi
        fi
else
    echo "👉 Skipping Laravel automations because we could not detect a Laravel install or it was specifically disabled..."
fi

exit 0