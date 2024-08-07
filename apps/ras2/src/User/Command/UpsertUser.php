<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Command;

use Ramona\Ras2\CQRS\Command\Command;
use Ramona\Ras2\User\UserId;

final readonly class UpsertUser implements Command
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(
        public UserId $id,
        public string $name
    ) {
    }
}
