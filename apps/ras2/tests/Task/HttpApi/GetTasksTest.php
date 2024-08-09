<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\HttpApi;

use Doctrine\Common\Collections\ArrayCollection;
use Laminas\Diactoros\ServerRequest;
use League\Route\Http\Exception\NotFoundException;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Application\SerializerFactory;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Bus;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultSerializer;
use Ramona\Ras2\Task\HttpApi\GetTasks;
use Ramona\Ras2\Task\Query\FindRandom;
use Ramona\Ras2\Task\Query\FindUpcoming;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\Task\TaskView;
use Ramona\Ras2\User\UserId;
use Tests\Ramona\Ras2\Task\Mocks\MockFindRandomExecutor;
use Tests\Ramona\Ras2\Task\Mocks\MockFindUpcomingExecutor;

final class GetTasksTest extends TestCase
{
    public function testThrowsOnMissingAction(): void
    {
        $request = new ServerRequest();

        $controller = new GetTasks(new Bus(), new DefaultSerializer(new DefaultDehydrator()));

        $this->expectException(NotFoundException::class);
        ($controller)($request);
    }

    public function testWillExecuteQueryForUpcoming(): void
    {
        $request = new ServerRequest(queryParams: [
            'limit' => 123,
            'assigneeId' => '019137b7-d4da-7d6f-9200-400eb263f3fb',
            'action' => 'upcoming',
        ]);

        $bus = new Bus();
        $result = new TaskView(TaskId::generate(), 'Title', 'ramona', new ArrayCollection(['tag1', 'tag2']), null);
        $executor = new MockFindUpcomingExecutor([$result]);

        $bus->installExecutor(FindUpcoming::class, $executor);
        $serializer = (new SerializerFactory())->create();

        $controller = new GetTasks($bus, $serializer);

        $response = ($controller)($request);
        $response->getBody()
            ->seek(0);

        self::assertEquals(
            new FindUpcoming(123, UserId::fromString('019137b7-d4da-7d6f-9200-400eb263f3fb')),
            $executor->query
        );
        self::assertJsonStringEqualsJsonString(
            $serializer->serialize(new ArrayCollection([$result])),
            $response->getBody()
                ->getContents()
        );
        self::assertEquals('application/json', $response->getHeaderLine('Content-Type'));
    }

    public function testWatched(): void
    {
        $request = new ServerRequest(queryParams: [
            'limit' => 123,
            'action' => 'watched',
        ]);

        $bus = new Bus();
        $result = new TaskView(TaskId::generate(), 'Title', 'ramona', new ArrayCollection(['tag1', 'tag2']), null);
        $executor = new MockFindRandomExecutor([$result]);

        $bus->installExecutor(FindRandom::class, $executor);
        $serializer = (new SerializerFactory())->create();

        $controller = new GetTasks($bus, $serializer);

        $response = ($controller)($request);
        $response->getBody()
            ->seek(0);

        self::assertEquals(new FindRandom(123), $executor->query);
        self::assertJsonStringEqualsJsonString(
            $serializer->serialize(new ArrayCollection([$result])),
            $response->getBody()
                ->getContents()
        );
        self::assertEquals('application/json', $response->getHeaderLine('Content-Type'));

    }
}
