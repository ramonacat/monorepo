<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2;

use Ramona\Ras2\SharedCore\Infrastructure\ClassFinder;
use Symfony\Component\Cache\Adapter\FilesystemAdapter;
use Symfony\Component\Cache\Psr16Cache;

final class ClassFinderFactory
{
    public static function create(): ClassFinder
    {
        $cache = new FilesystemAdapter();
        return new ClassFinder(new Psr16Cache($cache));
    }
}
