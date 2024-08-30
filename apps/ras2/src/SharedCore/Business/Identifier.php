<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Business;

use Stringable;

interface Identifier extends Stringable
{
    public static function generate(): static;

    public static function fromString(string $id): static;
}
