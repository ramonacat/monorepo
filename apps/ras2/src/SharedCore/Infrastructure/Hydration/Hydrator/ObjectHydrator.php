<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\CannotHydrateType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\HydrateFromSession;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\HydrationAttribute;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\MissingInputValue;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;

/**
 * @template T of object
 * @implements ValueHydrator<T>
 */
final class ObjectHydrator implements ValueHydrator
{
    /**
     * @param class-string<T> $className
     */
    public function __construct(
        private string $className
    ) {
    }

    /**
     * @psalm-suppress MixedAssignment
     * @psalm-suppress MixedArgument
     */
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
    {
        $reflectionClass = new \ReflectionClass($this->className);
        $instance = $reflectionClass->newInstanceWithoutConstructor();
        foreach ($reflectionClass->getProperties() as $property) {
            $type = $property->getType();

            if (! ($type instanceof \ReflectionNamedType)) {
                throw CannotHydrateType::for((string) ($type ?? '<missing>'));
            }

            $propertyName = $property->getName();
            $sessionValue = null;
            $hasSessionValue = false;

            $fromSessionAttribute = $property->getAttributes(HydrateFromSession::class);
            if (count($fromSessionAttribute) === 1 && ($session = $hydrator->session()) !== null) {
                /** @var HydrateFromSession $attribute */
                $attribute = $fromSessionAttribute[0]->newInstance();

                assert(property_exists($session, $attribute->fieldName));
                /**
                 * @phpstan-ignore property.dynamicName
                 */
                $sessionValue = $session->{$attribute->fieldName};
                $hasSessionValue = true;
            }
            if (! array_key_exists($propertyName, $input) && ! $hasSessionValue) {
                throw MissingInputValue::forProperty($propertyName);
            }

            /** @var list<HydrationAttribute> $newAttributes */
            $newAttributes = [];
            foreach ($property->getAttributes() as $attribute) {
                $attributeInstance = $attribute->newInstance();

                if ($attributeInstance instanceof HydrationAttribute) {
                    $newAttributes[] = $attributeInstance;
                }
            }

            $value = $input[$propertyName] ?? $sessionValue;
            if ($value === null && ! $type->allowsNull()) {
                throw CannotHydrateType::for('null');
            }

            if ($value !== null && $sessionValue === null) {
                $targetType = $type->getName();
                /** @var class-string $targetType */
                $value = $hydrator->hydrate($targetType, $value, $newAttributes);
            }
            $property->setValue($instance, $value);
        }

        return $instance;
    }

    public function handles(): string
    {
        return $this->className;
    }
}
