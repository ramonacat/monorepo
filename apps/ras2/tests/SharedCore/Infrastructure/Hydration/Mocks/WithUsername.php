<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\Hydration\Mocks;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\HydrateFromSession;

final class WithUsername
{
    #[HydrateFromSession('username')]
    public string $username;
}
