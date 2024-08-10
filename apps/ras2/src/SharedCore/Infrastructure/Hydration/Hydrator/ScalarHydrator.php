<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;

/**
 * @implements ValueHydrator<scalar>
 */
final class ScalarHydrator implements ValueHydrator
{
    /**
     * @param 'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL' $typeName
     */
    public function __construct(
        private string $typeName
    ) {
    }

    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
    {
        assert(is_scalar($input));
        return $input;
    }

    public function handles(): string
    {
        return $this->typeName;
    }
}
