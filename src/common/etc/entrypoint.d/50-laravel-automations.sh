#!/bin/sh
script_name="laravel-automations"

# Global configurations
: "${DISABLE_DEFAULT_CONFIG:=false}"
: "${APP_BASE_DIR:=/var/www/html}"

# Set default values for Laravel automations
: "${AUTORUN_ENABLED:=false}"
: "${AUTORUN_DEBUG:=false}"

# Set default values for storage link
: "${AUTORUN_LARAVEL_STORAGE_LINK:=true}"

# Set default values for optimizations
: "${AUTORUN_LARAVEL_OPTIMIZE:=true}"
: "${AUTORUN_LARAVEL_CONFIG_CACHE:=true}"
: "${AUTORUN_LARAVEL_ROUTE_CACHE:=true}"
: "${AUTORUN_LARAVEL_VIEW_CACHE:=true}"
: "${AUTORUN_LARAVEL_EVENT_CACHE:=true}"

# Set default values for Migrations
: "${AUTORUN_LARAVEL_MIGRATION:=true}"
: "${AUTORUN_LARAVEL_MIGRATION_ISOLATION:=false}"
: "${AUTORUN_LARAVEL_MIGRATION_TIMEOUT:=30}"

# Set default values for Laravel version
INSTALLED_LARAVEL_VERSION=""

############################################################################
# Sanity Checks
############################################################################

debug_log() {
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ] || [ "$AUTORUN_DEBUG" = "true" ]; then
        echo "👉 DEBUG ($script_name): $1" >&2
    fi
}

if [ "$DISABLE_DEFAULT_CONFIG" = "true" ] || [ "$AUTORUN_ENABLED" = "false" ]; then
    debug_log "Skipping Laravel automations because DISABLE_DEFAULT_CONFIG is true or AUTORUN_ENABLED is false."
    exit 0
fi

############################################################################
# Functions
############################################################################

artisan_migrate() {
    count=0
    timeout=$AUTORUN_LARAVEL_MIGRATION_TIMEOUT

    debug_log "Starting migrations (timeout: ${timeout}s, isolation: $AUTORUN_LARAVEL_MIGRATION_ISOLATION)"

    echo "🚀 Clearing Laravel cache before attempting migrations..."
    php "$APP_BASE_DIR/artisan" config:clear

    # Do not exit on error for this loop
    set +e
    echo "⚡️ Attempting database connection..."
    while [ $count -lt "$timeout" ]; do
        if [ "$AUTORUN_DEBUG" = "true" ]; then
            # Show output when debug is enabled
            test_db_connection
        else
            # Otherwise suppress output
            test_db_connection > /dev/null 2>&1
        fi
        status=$?
        if [ $status -eq 0 ]; then
            echo "✅ Database connection successful."
            break
        else
            # Only log every 5 attempts to reduce noise
            if [ $((count % 5)) -eq 0 ]; then
                debug_log "Connection attempt $((count + 1))/$timeout failed (status: $status)"
            fi
            echo "Waiting on database connection, retrying... $((timeout - count)) seconds left"
            count=$((count + 1))
            sleep 1
        fi
    done

    # Re-enable exit on error
    set -e

    if [ $count -eq "$timeout" ]; then
        echo "❌ $script_name: Database connection failed after multiple attempts."
        debug_log "Database connection timed out after $timeout seconds"
        return 1
    fi
    
    if [ "$AUTORUN_LARAVEL_MIGRATION_ISOLATION" = "true" ] && laravel_version_is_at_least "9.38.0"; then
        debug_log "Running migrations with --isolated flag"
        echo "🚀 Running migrations: \"php artisan migrate --force --isolated\"..."
        php "$APP_BASE_DIR/artisan" migrate --force --isolated
    else
        debug_log "Running standard migrations"
        echo "🚀 Running migrations: \"php artisan migrate --force\"..."
        php "$APP_BASE_DIR/artisan" migrate --force
    fi
}

artisan_storage_link() {
    if [ -d "$APP_BASE_DIR/public/storage" ]; then
        echo "✅ Storage already linked..."
    else
        echo "🔐 Running storage link: \"php artisan storage:link\"..."
        php "$APP_BASE_DIR/artisan" storage:link
    fi
}

artisan_optimize() {
    # Case 1: All optimizations are enabled - use simple optimize command
    if [ "$AUTORUN_LARAVEL_OPTIMIZE" = "true" ] && \
       [ "$AUTORUN_LARAVEL_CONFIG_CACHE" = "true" ] && \
       [ "$AUTORUN_LARAVEL_ROUTE_CACHE" = "true" ] && \
       [ "$AUTORUN_LARAVEL_VIEW_CACHE" = "true" ] && \
       [ "$AUTORUN_LARAVEL_EVENT_CACHE" = "true" ]; then
        echo "🚀 Running optimize command: \"php artisan optimize\"..."
        if ! php "$APP_BASE_DIR/artisan" optimize; then
            echo "❌ Laravel optimize failed"
            return 1
        fi
        return 0
    fi

    # Case 2: AUTORUN_LARAVEL_OPTIMIZE is true but some optimizations disabled
    if [ "$AUTORUN_LARAVEL_OPTIMIZE" = "true" ] && laravel_version_is_at_least "11.38.0"; then
        echo "🛠️ Preparing optimizations..."
        except=""
        
        # Build except string for disabled optimizations
        [ "$AUTORUN_LARAVEL_CONFIG_CACHE" = "false" ] && except="${except:+${except},}config"
        [ "$AUTORUN_LARAVEL_ROUTE_CACHE" = "false" ] && except="${except:+${except},}routes"
        [ "$AUTORUN_LARAVEL_VIEW_CACHE" = "false" ] && except="${except:+${except},}views"
        [ "$AUTORUN_LARAVEL_EVENT_CACHE" = "false" ] && except="${except:+${except},}events"
        
        echo "🛠️ Running optimizations: \"php artisan optimize ${except:+--except=${except}}\"..."
        if ! php "$APP_BASE_DIR/artisan" optimize ${except:+--except=${except}}; then
            echo "$script_name: ❌ Laravel optimize failed"
            return 1
        fi
        return 0
    fi

    if [ "$AUTORUN_LARAVEL_OPTIMIZE" = "true" ] && ! laravel_version_is_at_least "11.38.0"; then
        echo "ℹ️ Granular optimizations require Laravel v11.38.0 or above, using individual optimizations instead..."
    fi

    # Case 3: Individual optimizations when AUTORUN_LARAVEL_OPTIMIZE is false
    has_error=0
    
    if [ "$AUTORUN_LARAVEL_CONFIG_CACHE" = "true" ]; then
        echo "🚀 Caching config: \"php artisan config:cache\"..."
        php "$APP_BASE_DIR/artisan" config:cache || has_error=1
    fi

    if [ "$AUTORUN_LARAVEL_ROUTE_CACHE" = "true" ]; then
        echo "🚀 Caching routes: \"php artisan route:cache\"..."
        php "$APP_BASE_DIR/artisan" route:cache || has_error=1
    fi

    if [ "$AUTORUN_LARAVEL_VIEW_CACHE" = "true" ]; then
        echo "🚀 Caching views: \"php artisan view:cache\"..."
        php "$APP_BASE_DIR/artisan" view:cache || has_error=1
    fi

    if [ "$AUTORUN_LARAVEL_EVENT_CACHE" = "true" ]; then
        echo "🚀 Caching events: \"php artisan event:cache\"..."
        php "$APP_BASE_DIR/artisan" event:cache || has_error=1
    fi

    return $has_error
}

get_laravel_version() {
    # Return cached version if already set
    if [ -n "$INSTALLED_LARAVEL_VERSION" ]; then
        debug_log "Using cached Laravel version: $INSTALLED_LARAVEL_VERSION"
        echo "$INSTALLED_LARAVEL_VERSION"
        return 0
    fi

    debug_log "Detecting Laravel version..."
    # Use 2>/dev/null to handle potential PHP warnings
    artisan_version_output=$(php "$APP_BASE_DIR/artisan" --version 2>/dev/null)
    
    # Check if command was successful
    if [ $? -ne 0 ]; then
        echo "❌ $script_name: Failed to execute artisan command" >&2
        return 1
    fi
    
    # Extract version number using sed (POSIX compliant)
    # Using a more strict pattern that matches "Laravel Framework X.Y.Z"
    laravel_version=$(echo "$artisan_version_output" | sed -e 's/^Laravel Framework \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*$/\1/')
    
    # Validate that we got a version number (POSIX compliant regex)
    if echo "$laravel_version" | grep '^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null 2>&1; then
        INSTALLED_LARAVEL_VERSION="$laravel_version"
        debug_log "Detected Laravel version: $laravel_version"
        echo "$laravel_version"
        return 0
    else
        echo "❌ $script_name: Failed to determine Laravel version" >&2
        return 1
    fi
}

laravel_is_installed() {
    if [ ! -f "$APP_BASE_DIR/artisan" ]; then
        return 1
    fi

    if [ ! -d "$APP_BASE_DIR/vendor" ]; then
        return 1
    fi

    return 0
}

laravel_version_is_at_least() {
    required_version="$1"

    if [ -z "$required_version" ]; then
        echo "❌ $script_name - Usage: laravel_version_is_at_least <required_version>" >&2
        return 1
    fi

    # Validate required version format
    if ! echo "$required_version" | grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
        echo "❌ $script_name - Invalid version requirement format: $required_version" >&2
        return 1
    fi

    current_version=$(get_laravel_version)
    if [ $? -ne 0 ]; then
        echo "❌ $script_name: Failed to get Laravel version" >&2
        return 1
    fi

    # normalize_version() takes a version string and ensures it has 3 parts
    normalize_version() {
        echo "$1" | awk -F. '{ print $1"."$2"."(NF>2?$3:0) }'
    }

    normalized_current=$(normalize_version "$current_version")
    normalized_required=$(normalize_version "$required_version")

    # Use sort -V to get the lower version, then compare it with required version
    # This works in BusyBox because we only need to check the first line of output
    lowest_version=$(printf '%s\n%s\n' "$normalized_required" "$normalized_current" | sort -V | head -n1)
    if [ "$lowest_version" = "$normalized_required" ]; then
        return 0    # Success: current version is >= required version
    else
        return 1    # Failure: current version is < required version
    fi
}

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
# Main
############################################################################

if laravel_is_installed; then
    debug_log "Laravel detected: v$(get_laravel_version)"
    debug_log "Automation settings:"
    debug_log "- Storage Link: $AUTORUN_LARAVEL_STORAGE_LINK"
    debug_log "- Migrations: $AUTORUN_LARAVEL_MIGRATION"
    debug_log "- Migrations Isolation: $AUTORUN_LARAVEL_MIGRATION_ISOLATION"
    debug_log "- Optimize: $AUTORUN_LARAVEL_OPTIMIZE"
    debug_log "- Config Cache: $AUTORUN_LARAVEL_CONFIG_CACHE"
    debug_log "- Route Cache: $AUTORUN_LARAVEL_ROUTE_CACHE"
    debug_log "- View Cache: $AUTORUN_LARAVEL_VIEW_CACHE"
    debug_log "- Event Cache: $AUTORUN_LARAVEL_EVENT_CACHE"

    echo "🤔 Checking for Laravel automations..."
    if [ "$AUTORUN_LARAVEL_STORAGE_LINK" = "true" ]; then
        artisan_storage_link
    fi
    
    if [ "$AUTORUN_LARAVEL_MIGRATION" = "true" ]; then
        artisan_migrate
    fi

    if [ "$AUTORUN_LARAVEL_OPTIMIZE" = "true" ] || \
       [ "$AUTORUN_LARAVEL_CONFIG_CACHE" = "true" ] || \
       [ "$AUTORUN_LARAVEL_ROUTE_CACHE" = "true" ] || \
       [ "$AUTORUN_LARAVEL_VIEW_CACHE" = "true" ] || \
       [ "$AUTORUN_LARAVEL_EVENT_CACHE" = "true" ]; then
        artisan_optimize
    fi
else
    echo "👉 $script_name: Skipping Laravel automations because Laravel is not installed."
fi