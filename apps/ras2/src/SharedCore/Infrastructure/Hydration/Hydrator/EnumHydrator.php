<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\CannotHydrateType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;
use ReflectionEnum;

/**
 * @template T of \UnitEnum
 * @implements ValueHydrator<T>
 */
final class EnumHydrator implements ValueHydrator
{
    /**
     * @param class-string<T> $enumName
     */
    public function __construct(
        private string $enumName
    ) {
    }

    /**
     * @return T
     */
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
    {
        $reflection = new ReflectionEnum($this->enumName);

        foreach ($reflection->getCases() as $case) {
            if ($case->getName() === $input) {
                /** @phpstan-ignore return.type */
                return $case->getValue();
            }
        }

        throw new CannotHydrateType($this->enumName);
    }

    /**
     * @return class-string<T>
     */
    public function handles(): string
    {
        return $this->enumName;
    }
}
