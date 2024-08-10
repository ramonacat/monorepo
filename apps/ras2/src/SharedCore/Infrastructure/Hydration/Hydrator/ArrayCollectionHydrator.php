<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\InvalidArrayDeclaration;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueType;

/**
 * @implements ValueHydrator<ArrayCollection<array-key, mixed>>
 * @psalm-suppress MixedAssignment
 */
final class ArrayCollectionHydrator implements ValueHydrator
{
    /**
     * @psalm-suppress InvalidReturnStatement
     * @psalm-suppress InvalidReturnType
     */
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
            /**
             * @psalm-suppress MixedArrayOffset
             * @var class-string $keyType
             * @var class-string $valueType
             * @var array-key $hydratedKey
             */
            $hydratedKey = $hydrator->hydrate($keyType, $key);
            $result[$hydratedKey] = $hydrator->hydrate($valueType, $value);
        }

        return new ArrayCollection($result);
    }

    public function handles(): string
    {
        return ArrayCollection::class;
    }
}
