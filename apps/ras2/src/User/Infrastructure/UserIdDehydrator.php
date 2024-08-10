<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Infrastructure;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueDehydrator;
use Ramona\Ras2\User\Business\UserId;

/**
 * @implements ValueDehydrator<UserId>
 */
final class UserIdDehydrator implements ValueDehydrator
{
    public function dehydrate(Dehydrator $dehydrator, mixed $value): mixed
    {
        return (string) $value;
    }

    public function handles(): string
    {
        return UserId::class;
    }
}
