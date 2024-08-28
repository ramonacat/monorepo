<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition;

#[\Attribute(\Attribute::TARGET_CLASS)]
final readonly class APICommand
{
    public function __construct(
        public string $path,
        public string $name
    ) {
    }
}
