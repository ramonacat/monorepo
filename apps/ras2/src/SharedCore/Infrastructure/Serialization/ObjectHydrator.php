<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

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
            if (! array_key_exists($propertyName, $input)) {
                throw MissingInputValue::forProperty($propertyName);
            }

            /** @var list<SerializationAttribute> $newAttributes */
            $newAttributes = [];
            foreach ($property->getAttributes() as $attribute) {
                $attributeInstance = $attribute->newInstance();

                if ($attributeInstance instanceof SerializationAttribute) {
                    $newAttributes[] = $attributeInstance;
                }
            }

            if ($input[$propertyName] === null && ! $type->allowsNull()) {
                throw CannotHydrateType::for('null');
            }

            $value = null;
            if ($input[$propertyName] !== null) {
                $value = $hydrator->hydrate($type->getName(), $input[$propertyName], $newAttributes);
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
