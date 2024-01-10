#!/bin/sh
script_name="laravel-automations"

test_db_connection() {
    php -r "
        require '$APP_BASE_DIR/vendor/autoload.php';
        use DB;


        \$app = require_once '$APP_BASE_DIR/bootstrap/app.php';
        \$kernel = \$app->make(Illuminate\Contracts\Console\Kernel::class);
        \$kernel->bootstrap();

        try {
            \$pdo = DB::connection()->getPdo();
            \$dbName = DB::connection()->getDatabaseName();
            \$query = \$pdo->prepare('SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = ?');
            \$query->execute([\$dbName]);
            \$result = \$query->fetch();
            if (\$result) {
                exit(0); // Database exists, exit with status 0 (success)
            } else {
                echo 'Database ' . \$dbName . ' does not exist.';
                exit(1); // Database does not exist, exit with status 1 (failure)
            }
        } catch (Exception \$e) {
            echo 'Database connection error: ' . \$e->getMessage();
            exit(1); // Connection error, exit with status 1 (failure)
        }
    "
}

# Set default value for AUTORUN_ENABLED
: "${AUTORUN_ENABLED:=false}"

if [ "$DISABLE_DEFAULT_CONFIG" = "false" ]; then
    # Check to see if an Artisan file exists and assume it means Laravel is configured.
    if [ -f "$APP_BASE_DIR/artisan" ] && [ "$AUTORUN_ENABLED" = "true" ]; then
        echo "Checking for Laravel automations..."
        ############################################################################
        # artisan migrate
        ############################################################################
        if [ "${AUTORUN_LARAVEL_MIGRATION:=true}" = "true" ]; then
            count=0
            while [ $count -lt 30 ]; do
                test_db_connection > /dev/null 2>&1
                status=$?
                if [ $status -eq 0 ]; then
                    echo "✅ Database connection successful."
                    break
                else
                    echo "Waiting on database connection, retrying... $((30 - count)) seconds left"
                    count=$((count + 1))
                    sleep 1
                fi
            done

            if [ $count -eq 30 ]; then
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
    if [ "$LOG_LEVEL" = "debug" ]; then
        echo "👉 $script_name: DISABLE_DEFAULT_CONFIG does not equal 'false', so automations will NOT be performed."
    fi
fi