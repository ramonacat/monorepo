<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

use Psr\Log\LoggerInterface;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;

final readonly class DefaultSerializer implements Serializer
{
    public function __construct(
        private Dehydrator $dehydrator,
        private LoggerInterface $logger
    ) {
    }

    public function serialize(mixed $value): string
    {
        $this->logger->debug('Serializing', [
            'value' => $value,
        ]);
        return \Safe\json_encode($this->dehydrator->dehydrate($value));
    }
}
