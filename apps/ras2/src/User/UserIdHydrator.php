<?php

declare(strict_types=1);

namespace Ramona\Ras2\User;

use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ValueHydrator;

/**
 * @implements ValueHydrator<UserId>
 */
final class UserIdHydrator implements ValueHydrator
{
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
    {
        assert(is_string($input));
        return UserId::fromString($input);
    }

    public function handles(): string
    {
        return UserId::class;
    }
}
