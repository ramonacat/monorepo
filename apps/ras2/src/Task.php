<?php

declare(strict_types=1);

namespace Ramona\Ras2;

/** @psalm-suppress UnusedClass */
final class Task
{
    private string $description;

    public function __construct(string $description)
    {
        $this->description = $description;
    }

    public function description(): string
    {
        return $this->description;
    }
}
