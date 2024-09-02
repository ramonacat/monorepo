<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query;

use RuntimeException;

final class NoExecutor extends RuntimeException
{
    public static function forQueryClass(string $queryClass): self
    {
        return new self("Executor not found for a query of class \"{$queryClass}\"");
    }
}
