<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application\Command;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\User\Business\UserId;

final readonly class UpsertUser implements Command
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(
        public UserId $id,
        public string $name,
        public bool $isSystem,
        public \DateTimeZone $timezone
    ) {
    }
}
