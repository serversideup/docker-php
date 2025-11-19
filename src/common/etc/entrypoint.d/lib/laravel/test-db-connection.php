<?php
/**
 * Test Laravel Database Connection
 * 
 * This script tests if the Laravel application can connect to its configured database.
 * It's designed to be called from shell scripts during container initialization.
 * 
 * Usage: php test-db-connection.php /path/to/app/base/dir [migration_mode] [migration_isolation] [database_connection]
 * 
 * Arguments:
 *   app_base_dir    - Path to Laravel application root
 *   migration_mode  - Migration mode: 'default', 'fresh', or 'refresh' (optional, defaults to 'default')
 *   migration_isolation - Whether to run migrations in isolation (optional, defaults to 'false')
 *   database_connection - Name of the database connection to test (optional, defaults to 'default')
 * 
 * Exit codes:
 *   0 - Success: Database is ready and accessible
 *   1 - Failure: Database connection failed or other error
 * 
 * @package serversideup/php
 */

// Validate arguments
if ($argc < 2 || $argc > 5) {
    fwrite(STDERR, "Usage: php test-db-connection.php /path/to/app/base/dir [migration_mode] [migration_isolation] [database_connection]\n");
    exit(1);
}

$appBaseDir = $argv[1];
$migrationMode = $argc >= 3 ? $argv[2] : 'default';
$migrationIsolation = $argc >= 4 ? $argv[3] : 'false';
$databaseConnection = $argc >= 5 ? $argv[4] : null;

// Validate migration mode
$validModes = ['default', 'fresh', 'refresh'];
if (!in_array($migrationMode, $validModes)) {
    fwrite(STDERR, "Error: Invalid migration mode '{$migrationMode}'. Must be one of: " . implode(', ', $validModes) . "\n");
    exit(1);
}

// Validate migration isolation
$validIsolations = ['true', 'false'];
if (!in_array($migrationIsolation, $validIsolations)) {
    fwrite(STDERR, "Error: Invalid migration isolation '{$migrationIsolation}'. Must be one of: " . implode(', ', $validIsolations) . "\n");
    exit(1);
}

// Validate that the app base directory exists
if (!is_dir($appBaseDir)) {
    fwrite(STDERR, "Error: App base directory does not exist: {$appBaseDir}\n");
    exit(1);
}

// Validate that required Laravel files exist
$vendorAutoload = "{$appBaseDir}/vendor/autoload.php";
$bootstrapApp = "{$appBaseDir}/bootstrap/app.php";

if (!file_exists($vendorAutoload)) {
    fwrite(STDERR, "Error: Composer autoload file not found: {$vendorAutoload}\n");
    exit(1);
}

if (!file_exists($bootstrapApp)) {
    fwrite(STDERR, "Error: Laravel bootstrap file not found: {$bootstrapApp}\n");
    exit(1);
}

// Bootstrap Laravel
try {
    require $vendorAutoload;
    
    $app = require_once $bootstrapApp;
    $kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
    $kernel->bootstrap();
    
} catch (Exception $e) {
    fwrite(STDERR, "Error bootstrapping Laravel: {$e->getMessage()}\n");
    exit(1);
}

// Test database connection
try {
    // Use specific database connection if provided
    $connection = $databaseConnection ? DB::connection($databaseConnection) : DB::connection();
    $driver = $connection->getDriverName();
    
    // SQLite special handling
    if ($driver === 'sqlite') {
        $dbPath = $connection->getDatabaseName();
        
        // Handle in-memory SQLite databases
        if ($dbPath === ':memory:') {
            fwrite(STDOUT, "SQLite in-memory database detected - ready\n");
            exit(0);
        }
        
        $dbDirectory = dirname($dbPath);
        
        // Check if database file already exists
        if (file_exists($dbPath)) {
            fwrite(STDOUT, "SQLite database file exists: {$dbPath}\n");
            exit(0);
        }
        
        // Database file doesn't exist - check if directory exists and is writable
        if (!is_dir($dbDirectory)) {
            fwrite(STDERR, "SQLite database directory does not exist: {$dbDirectory}\n");
            fwrite(STDERR, "Please create the directory before running migrations.\n");
            fwrite(STDERR, "Example: mkdir -p {$dbDirectory}\n");
            exit(1);
        }
        
        if (!is_writable($dbDirectory)) {
            fwrite(STDERR, "SQLite database directory is not writable: {$dbDirectory}\n");
            fwrite(STDERR, "Please check directory permissions.\n");
            exit(1);
        }
        
        // For 'fresh' and 'refresh' modes, the database file must already exist
        if ($migrationMode === 'fresh' || $migrationMode === 'refresh') {
            fwrite(STDERR, "SQLite database file does not exist: {$dbPath}\n");
            fwrite(STDERR, "Migration mode '{$migrationMode}' requires the database file to exist.\n");
            fwrite(STDERR, "Either:\n");
            fwrite(STDERR, "  1. Create the database (ensure it has read and write permissions for your user): touch {$dbPath}\n");
            fwrite(STDERR, "  2. Use AUTORUN_LARAVEL_MIGRATION_MODE=default to let Laravel create it\n");
            exit(1);
        }
        
        // For isolated migrations, the database file must exist (even in default mode)
        if ($migrationIsolation === 'true') {
            fwrite(STDERR, "SQLite database file does not exist: {$dbPath}\n");
            fwrite(STDERR, "Isolated migrations require the database file to exist before running.\n");
            fwrite(STDERR, "Either:\n");
            fwrite(STDERR, "  1. Create the database (ensure it has read and write permissions for your user): touch {$dbPath}\n");
            fwrite(STDERR, "  2. Set AUTORUN_LARAVEL_MIGRATION_ISOLATION=false to let migrations create it\n");
            exit(1);
        }
        
        // Directory exists and is writable - migrations can create the database file (default mode only)
        fwrite(STDOUT, "SQLite database directory is ready - migrations will create database\n");
        exit(0);
    }
    
    // Test connection for other database drivers
    $connection->getPdo();
    
    if ($connection->getDatabaseName()) {
        $connectionName = $databaseConnection ? " ({$databaseConnection})" : '';
        fwrite(STDOUT, "Database connection successful ({$driver}){$connectionName}\n");
        exit(0);
    } else {
        fwrite(STDERR, "Database name not found\n");
        exit(1);
    }
    
} catch (Exception $e) {
    $connectionName = $databaseConnection ? " ({$databaseConnection})" : '';
    fwrite(STDERR, "Database connection error{$connectionName}: {$e->getMessage()}\n");
    exit(1);
}