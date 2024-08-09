<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

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
    public function deserialize(string $targetType, string $raw): mixed
    {
        $decoded = \Safe\json_decode($raw, true);

        return $this->hydrator->hydrate($targetType, $decoded, []);
    }
}
