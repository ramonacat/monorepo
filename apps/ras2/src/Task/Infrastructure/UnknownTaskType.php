<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure;

use RuntimeException;

final class UnknownTaskType extends RuntimeException
{
    public static function of(string $className): self
    {
        return new self(sprintf('Unknown task type "%s"', $className));
    }
}
