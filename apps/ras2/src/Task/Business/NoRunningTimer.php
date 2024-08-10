<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

final class NoRunningTimer extends \RuntimeException
{
    public static function create(): self
    {
        return new self('There is no currently running timer');
    }
}
