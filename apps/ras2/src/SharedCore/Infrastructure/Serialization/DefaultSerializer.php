<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

final class DefaultSerializer implements Serializer
{
    public function __construct(
        private Dehydrator $dehydrator
    ) {
    }

    public function serialize(mixed $value): string
    {
        return \Safe\json_encode($this->dehydrator->dehydrate($value));
    }
}
