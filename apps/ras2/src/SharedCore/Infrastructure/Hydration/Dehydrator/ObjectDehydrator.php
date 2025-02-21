<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueDehydrator;
use ReflectionClass;

/**
 * @template T of object
 * @implements ValueDehydrator<T>
 */
final class ObjectDehydrator implements ValueDehydrator
{
    /**
     * @param class-string<T> $className
     */
    public function __construct(
        private string $className
    ) {
    }

    /**
     * @return array<string, scalar>
     */
    public function dehydrate(Dehydrator $dehydrator, mixed $value): array
    {
        $classReflection = new ReflectionClass($value);

        $result = [];
        foreach ($classReflection->getProperties() as $property) {
            /** @psalm-suppress MixedAssignment */
            $result[$property->getName()] = $dehydrator->dehydrate($property->getValue($value));
        }

        return $result;
    }

    /**
     * @return class-string<T>
     */
    public function handles(): string
    {
        return $this->className;
    }
}
