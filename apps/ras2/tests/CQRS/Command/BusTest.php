<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\CQRS\Command;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\CQRS\Command\Bus;
use Tests\Ramona\Ras2\CQRS\Command\Mocks\MockCommand;
use Tests\Ramona\Ras2\CQRS\Command\Mocks\MockCommandExecutor;

final class BusTest extends TestCase
{
    public function testCanDispatchACommand(): void
    {
        $bus = new Bus();
        $executor = new MockCommandExecutor();

        $bus->installExecutor(MockCommand::class, $executor);

        $command = new MockCommand();
        $bus->execute($command);

        self::assertSame($command, $executor->receivedCommand);
    }
}
