<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

use Psr\Log\LoggerInterface;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

final class DefaultDeserializer implements Deserializer
{
    public function __construct(
        private Hydrator $hydrator,
        private LoggerInterface $logger
    ) {
    }

    /**
     * @psalm-suppress MixedInferredReturnType
     * @psalm-suppress MixedAssignment
     * @psalm-suppress MixedReturnStatement
     */
    public function deserialize(string $targetType, string $raw, array $attributes = []): mixed
    {
        $this->logger->debug('Deserializing', [
            'targetType' => $targetType,
            'raw' => $raw,
            'attributes' => $attributes,
        ]);
        $decoded = \Safe\json_decode($raw, true);

        return $this->hydrator->hydrate($targetType, $decoded, $attributes);
    }
}
