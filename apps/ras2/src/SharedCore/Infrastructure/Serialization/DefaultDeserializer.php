<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

final class DefaultDeserializer implements Deserializer
{
    public function __construct(
        private Hydrator $hydrator
    ) {
    }

    /**
     * @psalm-suppress MixedInferredReturnType
     * @psalm-suppress MixedAssignment
     * @psalm-suppress MixedReturnStatement
     */
    public function deserialize(string $targetType, string $raw, array $attributes = []): mixed
    {
        $decoded = \Safe\json_decode($raw, true);

        return $this->hydrator->hydrate($targetType, $decoded, $attributes);
    }
}
