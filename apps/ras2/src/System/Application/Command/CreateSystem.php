<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Application\Command;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueType;
use Ramona\Ras2\System\Business\SystemId;
use Ramona\Ras2\System\Infrastructure\CommandExecutor\CreateSystemExecutor;

#[ExecutedBy(CreateSystemExecutor::class)]
final readonly class CreateSystem implements Command
{
    /**
     * @param ArrayCollection<string, string> $attributes
     */
    public function __construct(
        public SystemId $id,
        public string $hostname,
        public SystemType $type,
        #[KeyType('string')]
        #[ValueType('string')]
        public ArrayCollection $attributes
    ) {
    }
}
