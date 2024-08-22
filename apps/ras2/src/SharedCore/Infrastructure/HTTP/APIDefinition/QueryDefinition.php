<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;

final readonly class QueryDefinition
{
    /**
     * @template T
     * @param class-string<Query<T>> $queryType
     * @param class-string<T>|'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL' $responseType
     */
    public function __construct(
        public string $path,
        public string $queryName,
        public string $queryType,
        public string $responseType
    ) {
    }
}
