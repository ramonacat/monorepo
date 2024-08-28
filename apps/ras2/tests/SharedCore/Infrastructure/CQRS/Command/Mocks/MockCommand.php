<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Mocks;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;

#[ExecutedBy(MockCommandExecutor::class)]
final class MockCommand implements Command
{
    public string $value = 'abcd';
}
