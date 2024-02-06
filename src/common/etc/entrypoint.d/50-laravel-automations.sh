#!/bin/sh
script_name="laravel-automations"

test_db_connection() {
    php -r "
        require '$APP_BASE_DIR/vendor/autoload.php';
        use Illuminate\Support\Facades\DB;

        \$app = require_once '$APP_BASE_DIR/bootstrap/app.php';
        \$kernel = \$app->make(Illuminate\Contracts\Console\Kernel::class);
        \$kernel->bootstrap();

        try {
            DB::connection()->getPdo(); // Attempt to get PDO instance
            if (DB::connection()->getDatabaseName()) {
                exit(0); // Database exists and can be connected to, exit with status 0 (success)
            } else {
                echo 'Database name not found.';
                exit(1); // Database name not found, exit with status 1 (failure)
            }
        } catch (Exception \$e) {
            echo 'Database connection error: ' . \$e->getMessage();
            exit(1); // Connection error, exit with status 1 (failure)
        }
    "
}


# Set default values for Laravel automations
: "${AUTORUN_ENABLED:=false}"
: "${AUTORUN_LARAVEL_MIGRATION_TIMEOUT:=30}"

if [ "$DISABLE_DEFAULT_CONFIG" = "false" ]; then
    # Check to see if an Artisan file exists and assume it means Laravel is configured.
    if [ -f "$APP_BASE_DIR/artisan" ] && [ "$AUTORUN_ENABLED" = "true" ]; then
        echo "Checking for Laravel automations..."
        ############################################################################
        # artisan migrate
        ############################################################################
        if [ "${AUTORUN_LARAVEL_MIGRATION:=true}" = "true" ]; then
            count=0
            timeout=$AUTORUN_LARAVEL_MIGRATION_TIMEOUT
            while [ $count -lt "$timeout" ]; do
                test_db_connection > /dev/null 2>&1
                status=$?
                if [ $status -eq 0 ]; then
                    echo "✅ Database connection successful."
                    break
                else
                    echo "Waiting on database connection, retrying... $((timeout - count)) seconds left"
                    count=$((count + 1))
                    sleep 1
                fi
            done

            if [ $count -eq "$timeout" ]; then
                echo "Database connection failed after multiple attempts."
                exit 1
            fi

            echo "🚀 Running migrations..."
            php "$APP_BASE_DIR/artisan" migrate --force --isolated
        fi

        ############################################################################
        # artisan storage:link
        ############################################################################
        if [ "${AUTORUN_LARAVEL_STORAGE_LINK:=true}" = "true" ]; then
            if [ -d "$APP_BASE_DIR/public/storage" ]; then
                echo "✅ Storage already linked..."
            else
                echo "🔐 Linking the storage..."
                php "$APP_BASE_DIR/artisan" storage:link
            fi
        fi
        ############################################################################
        # artisan config:cache
        ############################################################################
        if [ "${AUTORUN_LARAVEL_CONFIG_CACHE:=true}" = "true" ]; then
            echo "🚀 Caching Laravel config..."
            php "$APP_BASE_DIR/artisan" config:cache
        fi

        ############################################################################
        # artisan route:cache
        ############################################################################
        if [ "${AUTORUN_LARAVEL_ROUTE_CACHE:=true}" = "true" ]; then
            echo "🚀 Caching Laravel routes..."
            php "$APP_BASE_DIR/artisan" route:cache
        fi

        ############################################################################
        # artisan view:cache
        ############################################################################
        if [ "${AUTORUN_LARAVEL_VIEW_CACHE:=true}" = "true" ]; then
            echo "🚀 Caching Laravel views..."
            php "$APP_BASE_DIR/artisan" view:cache
        fi

        ############################################################################
        # artisan event:cache
        ############################################################################
        if [ "${AUTORUN_LARAVEL_EVENT_CACHE:=true}" = "true" ]; then
            echo "🚀 Caching Laravel events..."
            php "$APP_BASE_DIR/artisan" event:cache
        fi
    fi
else
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        echo "👉 $script_name: DISABLE_DEFAULT_CONFIG does not equal 'false', so automations will NOT be performed."
    fi
fi