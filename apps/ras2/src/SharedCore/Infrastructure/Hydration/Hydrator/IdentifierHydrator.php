<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

use Ramona\Ras2\SharedCore\Business\Identifier;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;

/**
 * @template T of Identifier
 * @implements ValueHydrator<T>
 */
final class IdentifierHydrator implements ValueHydrator
{
    /**
     * @param class-string<T> $className
     */
    public function __construct(
        private string $className
    ) {
    }

    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
    {
        return $this->className::fromString((string) $input);
    }

    public function handles(): string
    {
        return $this->className;
    }
}
