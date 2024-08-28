<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Infrastructure\Infrastructure\CQRS\Command;

use DI\Container;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\DefaultCommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\NoExecutor;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Mocks\CommandWithoutExecutor;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Mocks\MockCommand;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Mocks\MockCommandExecutor;

final class BusTest extends TestCase
{
    public function testCanDispatchACommand(): void
    {
        $bus = new DefaultCommandBus(new Container());
        $executor = new MockCommandExecutor();

        $bus->installExecutor(MockCommand::class, $executor);

        $command = new MockCommand();
        $bus->execute($command);

        self::assertSame($command, $executor->receivedCommand);
    }

    public function testThrowsOnMissingExecutor(): void
    {
        $bus = new DefaultCommandBus(new Container());

        $this->expectException(NoExecutor::class);
        $this->expectExceptionMessage(
            "Could not find an executor for a command of type 'Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Mocks\CommandWithoutExecutor'"
        );
        $bus->execute(new CommandWithoutExecutor());
    }

    public function testCanUseAttribute(): void
    {
        $container = new Container();
        $executor = new MockCommandExecutor();
        $container->set(MockCommandExecutor::class, $executor);
        $bus = new DefaultCommandBus($container);

        $bus->execute(new MockCommand());

        self::assertEquals(new MockCommand(), $executor->receivedCommand);
    }
}
