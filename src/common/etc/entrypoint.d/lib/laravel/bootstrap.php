<?php
/**
 * Boots the Laravel app in $appBaseDir for the other helpers in this folder.
 * Exits 1 with the reason on STDERR when the app can't be booted.
 *
 * @package serversideup/php
 */

function bootstrap_laravel(string $appBaseDir): void
{
    if (!is_dir($appBaseDir)) {
        fwrite(STDERR, "Error: App base directory does not exist: {$appBaseDir}\n");
        exit(1);
    }

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

    try {
        require $vendorAutoload;

        $app = require_once $bootstrapApp;
        $kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
        $kernel->bootstrap();
    } catch (Throwable $e) {
        fwrite(STDERR, "Error bootstrapping Laravel: {$e->getMessage()}\n");
        exit(1);
    }
}
