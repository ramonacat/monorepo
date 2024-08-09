<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

/**
 * @implements ValueDehydrator<scalar>
 */
final class ScalarDehydrator implements ValueDehydrator
{
    /**
     * @param 'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL' $typeName
     */
    public function __construct(
        private string $typeName
    ) {
    }

    public function dehydrate(Dehydrator $dehydrator, mixed $value): mixed
    {
        return $value;
    }

    /**
     * @return 'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL'
     */
    public function handles(): string
    {
        return $this->typeName;
    }
}
