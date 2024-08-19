<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Event\Appplication\HttpApi;

use Laminas\Diactoros\ServerRequest;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Event\Application\Command\UpsertEvent;
use Ramona\Ras2\Event\Application\HttpApi\PostEvents;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\CommandExecutor;

final class PostEventsTest extends TestCase
{
    public function testCanUpsert(): void
    {
        $mock = $this->createMock(CommandExecutor::class);

        $request = new ServerRequest(headers: [
            'X-Action' => 'upsert',
        ]);
        $mock->expects(self::once())->method('execute')->with($request, [
            'upsert' => UpsertEvent::class,
        ]);
        $events = new PostEvents($mock);

        ($events)($request);
    }
}
