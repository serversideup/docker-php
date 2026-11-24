<?php
/**
 * Check whether Laravel Scout has index settings to sync
 *
 * `scout:sync-index-settings` prints an error on every start for engines that
 * can't take index settings, such as the database and collection drivers. This
 * runs the same checks first, so the automations only call it when it has work.
 *
 * Usage: php scout-has-index-settings.php /path/to/app/base/dir
 *
 * Exit codes:
 *   0 - The configured engine supports index settings, and some are configured
 *   1 - Nothing to sync, or the app or engine couldn't be loaded
 *
 * @package serversideup/php
 */

use Laravel\Scout\EngineManager;

if ($argc !== 2) {
    fwrite(STDERR, "Usage: php scout-has-index-settings.php /path/to/app/base/dir\n");
    exit(1);
}

require __DIR__ . '/bootstrap.php';
bootstrap_laravel($argv[1]);

try {
    $driver = config('scout.driver');
    $engine = app(EngineManager::class)->engine($driver);
} catch (Throwable $e) {
    fwrite(STDERR, "Error loading the Scout engine: {$e->getMessage()}\n");
    exit(1);
}

if (!method_exists($engine, 'updateIndexSettings')) {
    fwrite(STDOUT, "The \"{$driver}\" engine does not support index settings\n");
    exit(1);
}

if (empty(config("scout.{$driver}.index-settings"))) {
    fwrite(STDOUT, "No index settings configured for the \"{$driver}\" engine\n");
    exit(1);
}

fwrite(STDOUT, "Index settings configured for the \"{$driver}\" engine\n");
exit(0);
