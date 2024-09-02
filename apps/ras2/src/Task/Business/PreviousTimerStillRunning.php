<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use RuntimeException;

final class PreviousTimerStillRunning extends RuntimeException
{
    public static function create(): self
    {
        return new self('Previous timer is still running');
    }
}
