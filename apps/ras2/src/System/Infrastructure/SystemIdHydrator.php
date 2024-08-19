<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Infrastructure;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;
use Ramona\Ras2\System\Business\SystemId;

/**
 * @implements ValueHydrator<SystemId>
 */
final class SystemIdHydrator implements ValueHydrator
{
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
    {
        return SystemId::fromString($input);
    }

    public function handles(): string
    {
        return SystemId::class;
    }
}
