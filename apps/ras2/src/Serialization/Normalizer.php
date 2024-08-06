<?php

declare(strict_types=1);

namespace Ramona\Ras2\Serialization;

final class Normalizer
{
    /**
     * @var array<string, array{from-object:callable(object):mixed, to-object:callable(mixed):object}>
     */
    private array $converters = [];

    /**
     * @template T of object
     * @param class-string<T> $convertedType
     * @param callable(T):mixed $fromObject
     * @param callable(mixed):T $toObject
     */
    public function registerConverter(string $convertedType, callable $fromObject, callable $toObject): void
    {
        /**
         * @psalm-suppress PropertyTypeCoercion
         * @phpstan-ignore assign.propertyType
         */
        $this->converters[$convertedType] = [
            'from-object' => $fromObject,
            'to-object' => $toObject,
        ];
    }

    public function denormalize(object $raw): mixed
    {
        if (isset($this->converters[get_class($raw)])) {
            return $this->converters[get_class($raw)]['from-object']($raw);
        }

        $result = [];

        $reflectionClass = new \ReflectionClass($raw);
        foreach ($reflectionClass->getProperties() as $property) {
            /** @psalm-suppress MixedAssignment $value */
            $value = $property->getValue($raw);

            if (is_resource($value)) {
                throw ConversionNotFound::forValue($value, (string) $property->getType());
            }

            $propertyName = $property->getName();
            if (is_scalar($value) || is_array($value)) {
                $result[$propertyName] = $value;
                continue;
            }

            /** @var object|null $value */

            if ($value !== null && isset($this->converters[get_class($value)])) {
                /**
                 * @psalm-suppress MixedAssignment
                 */
                $result[$propertyName] = ($this->converters[get_class($value)]['from-object'])($value);
            } else {
                /**
                 * @psalm-suppress MixedAssignment
                 */
                $result[$propertyName] = $value === null ? null : $this->denormalize($value);
            }
        }

        return $result;
    }

    /**
     * @template T of object
     * @param array<string, mixed> $raw
     * @param class-string<T> $className
     * @return T
     */
    public function normalize(array $raw, string $className): object
    {
        if (isset($this->converters[$className])) {
            $result = $this->converters[$className]['to-object']($raw);

            assert($result instanceof $className);

            return $result;
        }

        $reflectionClass = new \ReflectionClass($className);
        $instance = $reflectionClass->newInstanceWithoutConstructor();
        $properties = $reflectionClass->getProperties();

        foreach ($properties as $property) {
            $propertyName = $property->getName();
            if (! \array_key_exists($propertyName, $raw)) {
                throw MissingDataForField::field($propertyName);
            }
            /** @var mixed $value */
            $value = $raw[$propertyName];
            $propertyType = $property->getType();
            if ($propertyType === null) {
                $property->setValue($instance, $value);
            } elseif ($propertyType instanceof \ReflectionNamedType) {
                $typeName = $propertyType->getName();

                if ($propertyType->isBuiltin() && ($propertyType->allowsNull() || $value !== null)) {
                    $property->setValue($instance, $value);
                    continue;
                }
                if (isset($this->converters[$typeName])) {
                    $property->setValue($instance, $this->converters[$typeName]['to-object']($value));
                    continue;
                } elseif (is_array($value) && $this->areAllKeysStrings($value)) {
                    assert(class_exists($typeName));
                    $property->setValue($instance, $this->normalize($value, $typeName));
                    continue;
                } elseif ($value === null && $propertyType->allowsNull()) {
                    $property->setValue($instance, null);
                    continue;
                }

                if ($value === null) {
                    throw MissingDataForField::isNull($propertyName);
                }

                throw ConversionNotFound::forValue($value, $typeName);
            } else {
                throw ConversionNotFound::forValue($value, (string) $propertyType);
            }
        }

        return $instance;
    }

    /**
     * @phpstan-assert-if-true array<string, mixed> $value
     * @psalm-assert-if-true  array<string, mixed> $value
     * @param array<array-key, mixed> $value
     */
    private function areAllKeysStrings(array $value): bool
    {
        foreach ($value as $key => $_) {
            if (! is_string($key)) {
                return false;
            }
        }

        return true;
    }
}
