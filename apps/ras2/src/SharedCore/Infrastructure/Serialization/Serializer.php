<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

interface Serializer
{
    public function serialize(mixed $value): string;
}
