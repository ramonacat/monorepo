<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

interface Dehydrator
{
    public function dehydrate(mixed $value): mixed;
}
