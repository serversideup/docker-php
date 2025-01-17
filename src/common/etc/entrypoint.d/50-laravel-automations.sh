#!/bin/sh
script_name="laravel-automations"

# Set default values for Laravel automations
: "${AUTORUN_ENABLED:=false}"
: "${AUTORUN_LARAVEL_STORAGE_LINK:=true}"

# Set default values for optimizations
: "${AUTRORUN_LARAVEL_OPTIMIZE:=false}"
: "${AUTORUN_LARAVEL_CONFIG_CACHE:=true}"
: "${AUTORUN_LARAVEL_ROUTE_CACHE:=true}"
: "${AUTORUN_LARAVEL_VIEW_CACHE:=true}"
: "${AUTORUN_LARAVEL_EVENT_CACHE:=true}"

# Set default values for Migrations
: "${AUTORUN_LARAVEL_MIGRATION:=true}"
: "${AUTORUN_LARAVEL_MIGRATION_ISOLATION:=false}"
: "${AUTORUN_LARAVEL_MIGRATION_TIMEOUT:=30}"

test_db_connection() {
    php -r "
        require '$APP_BASE_DIR/vendor/autoload.php';
        use Illuminate\Support\Facades\DB;

        \$app = require_once '$APP_BASE_DIR/bootstrap/app.php';
        \$kernel = \$app->make(Illuminate\Contracts\Console\Kernel::class);
        \$kernel->bootstrap();

        \$driver = DB::getDriverName();

            if( \$driver === 'sqlite' ){
                echo 'SQLite detected';
                exit(0); // Assume SQLite is always ready
            }

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

############################################################################
# artisan migrate
############################################################################
artisan_migrate() {
    if [ "$AUTORUN_LARAVEL_MIGRATION" = "true" ]; then
        count=0
        timeout=$AUTORUN_LARAVEL_MIGRATION_TIMEOUT
    
        echo "🚀 Clearing Laravel cache before attempting migrations..."
        php "$APP_BASE_DIR/artisan" config:clear
    
        # Do not exit on error for this loop
        set +e
        echo "⚡️ Attempting database connection..."
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
    
        # Re-enable exit on error
        set -e
    
        if [ $count -eq "$timeout" ]; then
            echo "Database connection failed after multiple attempts."
            return 1
        fi
    
        echo "🚀 Running migrations..."
        if [ "$AUTORUN_LARAVEL_MIGRATION_ISOLATION" = "true" ]; then
            php "$APP_BASE_DIR/artisan" migrate --force --isolated
        else
            php "$APP_BASE_DIR/artisan" migrate --force
        fi
    fi
}

############################################################################
# artisan storage:link
############################################################################
artisan_storage_link() {
    if [ "$AUTORUN_LARAVEL_STORAGE_LINK" = "true" ]; then
        if [ -d "$APP_BASE_DIR/public/storage" ]; then
            echo "✅ Storage already linked..."
        else
            echo "🔐 Linking the storage..."
            php "$APP_BASE_DIR/artisan" storage:link
        fi
    fi
}

############################################################################
# artisan optimize
############################################################################
artisan_optimize() {
    if [ "$AUTRORUN_LARAVEL_OPTIMIZE" = "true" ]; then
        echo "🚀 Optimizing Laravel..."

        # Get list of optimizations to skip
        except=""
    
        if [ "$AUTORUN_LARAVEL_CONFIG_CACHE" = "false" ]; then
            except="${except:+${except},}config"
        fi
    
        if [ "$AUTORUN_LARAVEL_ROUTE_CACHE" = "false" ]; then
            except="${except:+${except},}routes"
        fi
    
        if [ "$AUTORUN_LARAVEL_VIEW_CACHE" = "false" ]; then
            except="${except:+${except},}views"
        fi
    
        if [ "$AUTORUN_LARAVEL_EVENT_CACHE" = "false" ]; then
            except="${except:+${except},}views"
        fi
    
        except="${except:+--except=${except}}"
    
        # Attempt to run optimizations with exceptions, otherwise just run optimize
        if ! php "$APP_BASE_DIR/artisan" optimize "$except"; then
            echo "⚠️ Granular optimization requires Laravel v11.38 or above, running all optimizations..."
            php "$APP_BASE_DIR/artisan" optimize
        fi
    else
         # config:cache
        if [ "$AUTORUN_LARAVEL_CONFIG_CACHE" = "true" ]; then
            echo "🚀 Caching Laravel config..."
            php "$APP_BASE_DIR/artisan" config:cache
        fi
    
        # route:cache
        if [ "$AUTORUN_LARAVEL_ROUTE_CACHE" = "true" ]; then
            echo "🚀 Caching Laravel routes..."
            php "$APP_BASE_DIR/artisan" route:cache
        fi
    
        # view:cache
        if [ "$AUTORUN_LARAVEL_VIEW_CACHE" = "true" ]; then
            echo "🚀 Caching Laravel views..."
            php "$APP_BASE_DIR/artisan" view:cache
        fi
    
        # event:cache
        if [ "$AUTORUN_LARAVEL_EVENT_CACHE" = "true" ]; then
            echo "🚀 Caching Laravel events..."
            php "$APP_BASE_DIR/artisan" event:cache
        fi
    fi
}

if [ "$DISABLE_DEFAULT_CONFIG" = "false" ]; then
    # Check to see if an Artisan file exists and assume it means Laravel is configured.
    if [ -f "$APP_BASE_DIR/artisan" ] && [ "$AUTORUN_ENABLED" = "true" ]; then
        echo "💽 Checking for Laravel automations..."
        
        artisan_migrate
        
        artisan_storage_link
        
        artisan_optimize
        
    fi
else
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        echo "👉 $script_name: DISABLE_DEFAULT_CONFIG does not equal 'false', so automations will NOT be performed."
    fi
fi
