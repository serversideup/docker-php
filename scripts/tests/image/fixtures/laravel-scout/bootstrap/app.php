<?php
// fixtures/laravel with Laravel Scout installed, so lib/laravel/scout-has-index-settings.php
// can boot it. FAKE_SCOUT_DRIVER picks the engine: meilisearch (the default) takes
// index settings, others don't.

namespace Laravel\Scout {
    class MeilisearchEngine
    {
        public function updateIndexSettings() {}
    }

    class DatabaseEngine {}

    class EngineManager
    {
        public function engine($driver)
        {
            return $driver === 'meilisearch' ? new MeilisearchEngine() : new DatabaseEngine();
        }
    }
}

namespace {
    function config($key)
    {
        $driver = getenv('FAKE_SCOUT_DRIVER') ?: 'meilisearch';
        $config = [
            'scout.driver' => $driver,
            "scout.{$driver}.index-settings" => ['posts' => ['filterableAttributes' => ['organization_id']]],
        ];

        return $config[$key] ?? null;
    }

    function app($class)
    {
        return new $class();
    }

    return new class {
        public function make($class)
        {
            return $this;
        }

        public function bootstrap() {}
    };
}
