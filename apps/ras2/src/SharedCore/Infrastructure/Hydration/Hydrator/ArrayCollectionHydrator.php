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
 */
final class ArrayCollectionHydrator implements ValueHydrator
{
    /**
     * @return ArrayCollection<array-key, mixed>
     */
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): ArrayCollection
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
             * @var class-string $keyType
             * @var class-string $valueType
             * @var array-key $hydratedKey
             */
            /**
             * @phpstan-ignore varTag.type
             */
            $hydratedKey = $hydrator->hydrate($keyType, $key);
            $result[$hydratedKey] = $hydrator->hydrate($valueType, $value);
        }

        return new ArrayCollection($result);
    }

    /**
     * @return class-string<ArrayCollection<array-key, mixed>>
     */
    public function handles(): string
    {
        return ArrayCollection::class;
    }
}
