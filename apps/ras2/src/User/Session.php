<?php

declare(strict_types=1);

namespace Ramona\Ras2\User;

/**
 * @psalm-suppress PossiblyUnusedProperty
 * @psalm-suppress UnusedClass
 */
final readonly class Session
{
    public function __construct(
        public UserId $userId,
        public string $username
    ) {
    }
}
