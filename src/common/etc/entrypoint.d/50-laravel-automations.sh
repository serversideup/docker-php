#!/bin/sh
script_name="laravel-automations"

# Global configurations
: "${DISABLE_DEFAULT_CONFIG:=false}"
: "${APP_BASE_DIR:=/var/www/html}"
: "${AUTORUN_LIB_DIR:=/etc/entrypoint.d/lib}"

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
: "${AUTORUN_LARAVEL_MIGRATION_DATABASE:=}"
: "${AUTORUN_LARAVEL_MIGRATION_FORCE:=true}"
: "${AUTORUN_LARAVEL_MIGRATION_ISOLATION:=false}"
: "${AUTORUN_LARAVEL_MIGRATION_MODE:=default}"
: "${AUTORUN_LARAVEL_MIGRATION_SEED:=false}"
: "${AUTORUN_LARAVEL_MIGRATION_SKIP_DB_CHECK:=false}"
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
    migrate_flags=""

    debug_log "Starting migrations (isolation: $AUTORUN_LARAVEL_MIGRATION_ISOLATION)"

    echo "🚀 Clearing Laravel cache before attempting migrations..."
    php "$APP_BASE_DIR/artisan" config:clear
    
    # Determine the migration command to use
    case "$AUTORUN_LARAVEL_MIGRATION_MODE" in
        default)
            migration_command="migrate"
            ;;
        fresh)
            migration_command="migrate:fresh"
            ;;
        refresh)
            migration_command="migrate:refresh"
            ;;
    esac

    # Build migration flags (used for all databases)
    if [ "$AUTORUN_LARAVEL_MIGRATION_ISOLATION" = "true" ]; then
        # Isolation only works in default mode
        if [ "$AUTORUN_LARAVEL_MIGRATION_MODE" != "default" ]; then
            echo "❌ $script_name: Isolated migrations are only supported in default mode."
            return 1
        fi
        
        # Isolation requires Laravel 9.38.0+
        if ! laravel_version_is_at_least "9.38.0"; then
            echo "❌ $script_name: Isolated migrations require Laravel v9.38.0 or above. Detected version: $(get_laravel_version)"
            return 1
        fi
        
        migrate_flags="$migrate_flags --isolated"
    fi

    if [ "$AUTORUN_LARAVEL_MIGRATION_FORCE" = "true" ]; then
        migrate_flags="$migrate_flags --force"
    fi

    if [ "$AUTORUN_LARAVEL_MIGRATION_SEED" = "true" ]; then
        migrate_flags="$migrate_flags --seed"
    fi

    # Determine if multiple databases are specified
    if [ -n "$AUTORUN_LARAVEL_MIGRATION_DATABASE" ]; then
        databases=$(convert_comma_delimited_to_space_separated "$AUTORUN_LARAVEL_MIGRATION_DATABASE")
        database_list=$(echo "$databases" | tr ',' ' ')
        
        for db in $database_list; do
            # Wait for this specific database to be ready
            if ! wait_for_database_connection "$db"; then
                echo "❌ $script_name: Failed to connect to database: $db"
                return 1
            fi
            
            echo "🚀 Running migrations for database: $db"
            php "$APP_BASE_DIR/artisan" $migration_command --database=$db $migrate_flags
        done
    else
        # Wait for default database connection
        if ! wait_for_database_connection; then
            echo "❌ $script_name: Failed to connect to default database"
            return 1
        fi
        
        # Run migration with default database connection
        php "$APP_BASE_DIR/artisan" $migration_command $migrate_flags
    fi
}

artisan_storage_link() {
    if [ -d "$APP_BASE_DIR/public/storage" ]; then
        echo "✅ Storage already linked..."
        return 0
    else
        echo "🔐 Running storage link: \"php artisan storage:link\"..."
        if ! php "$APP_BASE_DIR/artisan" storage:link; then
            echo "❌ $script_name: Storage link failed"
            return 1
        fi
    fi
}

artisan_optimize() {
    debug_log "Starting Laravel optimizations..."
    
    # Determine which optimizations are requested
    all_opts_enabled="false"
    if [ "$AUTORUN_LARAVEL_OPTIMIZE" = "true" ] && \
       [ "$AUTORUN_LARAVEL_CONFIG_CACHE" = "true" ] && \
       [ "$AUTORUN_LARAVEL_ROUTE_CACHE" = "true" ] && \
       [ "$AUTORUN_LARAVEL_VIEW_CACHE" = "true" ] && \
       [ "$AUTORUN_LARAVEL_EVENT_CACHE" = "true" ]; then
        all_opts_enabled="true"
    fi
    
    # Case 1: All optimizations enabled - use simple optimize command
    if [ "$all_opts_enabled" = "true" ]; then
        debug_log "All optimizations enabled, using 'php artisan optimize'"
        echo "🚀 Running optimize command: \"php artisan optimize\"..."
        if ! php "$APP_BASE_DIR/artisan" optimize; then
            echo "❌ $script_name: Laravel optimize failed"
            return 1
        fi
        return 0
    fi
    
    # Case 2: AUTORUN_LARAVEL_OPTIMIZE is true with selective optimizations (Laravel 11.38.0+)
    if [ "$AUTORUN_LARAVEL_OPTIMIZE" = "true" ]; then
        if laravel_version_is_at_least "11.38.0"; then
            debug_log "Using 'php artisan optimize --except' for selective optimizations"
            echo "🛠️ Preparing selective optimizations..."
            except=""
            
            # Build except string for disabled optimizations
            [ "$AUTORUN_LARAVEL_CONFIG_CACHE" = "false" ] && except="${except:+${except},}config"
            [ "$AUTORUN_LARAVEL_ROUTE_CACHE" = "false" ] && except="${except:+${except},}routes"
            [ "$AUTORUN_LARAVEL_VIEW_CACHE" = "false" ] && except="${except:+${except},}views"
            [ "$AUTORUN_LARAVEL_EVENT_CACHE" = "false" ] && except="${except:+${except},}events"
            
            echo "🚀 Running optimizations: \"php artisan optimize ${except:+--except=${except}}\"..."
            if ! php "$APP_BASE_DIR/artisan" optimize ${except:+--except=${except}}; then
                echo "❌ $script_name: Laravel optimize failed"
                return 1
            fi
            return 0
        else
            debug_log "Laravel version < 11.38.0, falling back to individual optimization commands"
            echo "ℹ️ Selective optimizations with 'php artisan optimize --except' require Laravel v11.38.0 or above, using individual commands instead..."
        fi
    fi
    
    # Case 3: Run individual optimization commands
    # This runs when:
    # - AUTORUN_LARAVEL_OPTIMIZE is false (user wants granular control), OR
    # - AUTORUN_LARAVEL_OPTIMIZE is true but Laravel < 11.38.0 (fallback)
    debug_log "Running individual optimization commands"
    
    if [ "$AUTORUN_LARAVEL_CONFIG_CACHE" = "true" ]; then
        echo "🚀 Caching config: \"php artisan config:cache\"..."
        if ! php "$APP_BASE_DIR/artisan" config:cache; then
            echo "❌ $script_name: Config cache failed"
            return 1
        fi
    fi

    if [ "$AUTORUN_LARAVEL_ROUTE_CACHE" = "true" ]; then
        echo "🚀 Caching routes: \"php artisan route:cache\"..."
        if ! php "$APP_BASE_DIR/artisan" route:cache; then
            echo "❌ $script_name: Route cache failed"
            return 1
        fi
    fi

    if [ "$AUTORUN_LARAVEL_VIEW_CACHE" = "true" ]; then
        echo "🚀 Caching views: \"php artisan view:cache\"..."
        if ! php "$APP_BASE_DIR/artisan" view:cache; then
            echo "❌ $script_name: View cache failed"
            return 1
        fi
    fi

    if [ "$AUTORUN_LARAVEL_EVENT_CACHE" = "true" ]; then
        echo "🚀 Caching events: \"php artisan event:cache\"..."
        if ! php "$APP_BASE_DIR/artisan" event:cache; then
            echo "❌ $script_name: Event cache failed"
            return 1
        fi
    fi
    
    return 0
}

convert_comma_delimited_to_space_separated() {
    echo $1 | tr ',' ' '
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
    if [ "$AUTORUN_LARAVEL_MIGRATION_SKIP_DB_CHECK" = "true" ]; then
        return 0
    fi

    # Pass database connection name only if specified (not empty)
    database_arg="${1:-}"
    if [ -n "$database_arg" ]; then
        php "$AUTORUN_LIB_DIR/laravel/test-db-connection.php" "$APP_BASE_DIR" "$AUTORUN_LARAVEL_MIGRATION_MODE" "$AUTORUN_LARAVEL_MIGRATION_ISOLATION" "$database_arg"
    else
        php "$AUTORUN_LIB_DIR/laravel/test-db-connection.php" "$APP_BASE_DIR" "$AUTORUN_LARAVEL_MIGRATION_MODE" "$AUTORUN_LARAVEL_MIGRATION_ISOLATION"
    fi
}

wait_for_database_connection() {
    database_name="${1:-}"
    count=0
    timeout=$AUTORUN_LARAVEL_MIGRATION_TIMEOUT
    
    # Determine display name based on whether a specific connection was provided
    if [ -z "$database_name" ]; then
        display_name="default database"
        connection_label=""
    else
        display_name="database connection: $database_name"
        connection_label=": $database_name"
    fi

    debug_log "Waiting for connection to $display_name (timeout: ${timeout}s)"

    # Do not exit on error for this loop
    set +e
    echo "⚡️ Attempting connection to $display_name..."
    while [ $count -lt "$timeout" ]; do
        if [ "$AUTORUN_DEBUG" = "true" ]; then
            # Show output when debug is enabled
            # Only pass database_name if it's not empty
            if [ -z "$database_name" ]; then
                test_db_connection
            else
                test_db_connection "$database_name"
            fi
        else
            # Otherwise suppress output
            if [ -z "$database_name" ]; then
                test_db_connection > /dev/null 2>&1
            else
                test_db_connection "$database_name" > /dev/null 2>&1
            fi
        fi
        status=$?
        if [ $status -eq 0 ]; then
            echo "✅ Database connection successful$connection_label"
            set -e
            return 0
        else
            # Only log every 5 attempts to reduce noise
            if [ $((count % 5)) -eq 0 ]; then
                debug_log "Connection attempt $((count + 1))/$timeout failed for $display_name (status: $status)"
            fi
            echo "Waiting on $display_name connection, retrying... $((timeout - count)) seconds left"
            count=$((count + 1))
            sleep 1
        fi
    done

    # Re-enable exit on error
    set -e

    echo "❌ $script_name: Database connection to $display_name failed after $timeout seconds."
    debug_log "Database connection timed out for $display_name after $timeout seconds"
    return 1
}

############################################################################
# Main
############################################################################

if laravel_is_installed; then
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ] || [ "$AUTORUN_DEBUG" = "true" ]; then
        echo "Laravel detected: v$(get_laravel_version)"
        echo "Automation settings:"
        echo "--------------------------------"
        # Dynamically display all AUTORUN_* environment variables
        env | grep '^AUTORUN_' | sort | while IFS='=' read -r var_name var_value; do
            debug_log "- ${var_name}: ${var_value}"
        done
    fi

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
    echo "❌ $script_name: Could not detect Laravel installation."
    echo "ℹ️  Check that the application is installed in $APP_BASE_DIR"
    exit 1
fi