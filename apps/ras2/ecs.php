<?php

declare(strict_types=1);

use Symplify\EasyCodingStandard\Config\ECSConfig;

return ECSConfig::configure()
    ->withPaths([__DIR__ . '/src', __DIR__ . '/tests', __DIR__ . '/ecs.php'])
    ->withPreparedSets(psr12: true, common: true, symplify: true, strict: true, cleanCode: true);
