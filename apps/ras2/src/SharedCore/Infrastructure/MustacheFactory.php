<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure;

final class MustacheFactory
{
    public static function create(): \Mustache_Engine
    {
        $engine = new \Mustache_Engine([
            'escape' => fn ($x) => $x,
        ]);
        $engine->setLoader(new \Mustache_Loader_FilesystemLoader(__DIR__ . '/../../../queries/'));

        return $engine;
    }
}
