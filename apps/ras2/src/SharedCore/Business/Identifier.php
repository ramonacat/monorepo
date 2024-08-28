<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Business;

use Stringable;

interface Identifier extends Stringable
{
    public static function generate(): self;

    public static function fromString(string $id): self;
}
