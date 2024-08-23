<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Infrastructure;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueDehydrator;
use Ramona\Ras2\System\Business\SystemId;

/**
 * @implements ValueDehydrator<SystemId>
 */
final class SystemIdDehydrator implements ValueDehydrator
{
    public function dehydrate(Dehydrator $dehydrator, mixed $value): mixed
    {
        return (string) $value;
    }

    public function handles(): string
    {
        return SystemId::class;
    }
}
