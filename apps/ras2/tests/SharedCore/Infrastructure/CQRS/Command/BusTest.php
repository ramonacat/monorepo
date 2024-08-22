<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Infrastructure\Infrastructure\CQRS\Command;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\DefaultCommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\NoExecutor;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Mocks\MockCommand;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Mocks\MockCommandExecutor;

final class BusTest extends TestCase
{
    public function testCanDispatchACommand(): void
    {
        $bus = new DefaultCommandBus();
        $executor = new MockCommandExecutor();

        $bus->installExecutor(MockCommand::class, $executor);

        $command = new MockCommand();
        $bus->execute($command);

        self::assertSame($command, $executor->receivedCommand);
    }

    public function testThrowsOnMissingExecutor(): void
    {
        $bus = new DefaultCommandBus();

        $this->expectException(NoExecutor::class);
        $this->expectExceptionMessage(
            "Could not find an executor for a command of type 'Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Mocks\MockCommand'"
        );
        $bus->execute(new MockCommand());
    }
}
