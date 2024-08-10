<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection;

use Psr\Container\NotFoundExceptionInterface;

final class NotFound extends \RuntimeException implements NotFoundExceptionInterface
{
    public static function byId(string $id): self
    {
        return new self("A factory for '{$id}' was not found in the container.");
    }
}
