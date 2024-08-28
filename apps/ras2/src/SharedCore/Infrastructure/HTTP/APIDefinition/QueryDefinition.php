<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;

final readonly class QueryDefinition
{
    /**
     * @template T
     * @param class-string<Query<T>> $queryType
     */
    public function __construct(
        public string $path,
        public string $queryName,
        public string $queryType
    ) {
    }
}
