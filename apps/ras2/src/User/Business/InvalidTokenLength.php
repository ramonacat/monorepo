<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Business;

final class InvalidTokenLength extends \RuntimeException
{
    public static function for(int $expected, int $actual): self
    {
        return new self("Invalid token length, expected {$expected} bytes, but got {$actual}");
    }
}
