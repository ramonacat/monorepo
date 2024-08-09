<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @implements ValueHydrator<ArrayCollection<array-key, mixed>>
 * @psalm-suppress MixedAssignment
 */
final class ArrayCollectionHydrator implements ValueHydrator
{
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
    {
        $keyType = null;
        $valueType = null;

        foreach ($serializationAttributes as $attribute) {
            if ($attribute instanceof KeyType) {
                $keyType = $attribute->typeName;
            }

            if ($attribute instanceof ValueType) {
                $valueType = $attribute->typeName;
            }
        }

        if ($keyType === null || $valueType === null) {
            throw InvalidArrayDeclaration::missingKeyOrValue();
        }

        $result = [];
        foreach ($input as $key => $value) {
            /** @psalm-suppress MixedArrayOffset */
            $result[$hydrator->hydrate($keyType, $key, [])] = $hydrator->hydrate($valueType, $value, []);
        }

        return new ArrayCollection($result);
    }

    public function handles(): string
    {
        return ArrayCollection::class;
    }
}
