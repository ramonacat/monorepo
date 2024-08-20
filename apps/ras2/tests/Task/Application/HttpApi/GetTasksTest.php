<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Application\HttpApi;

use Doctrine\Common\Collections\ArrayCollection;
use Laminas\Diactoros\ServerRequest;
use Laminas\Diactoros\Stream;
use League\Route\Http\Exception\NotFoundException;
use Psr\Log\NullLogger;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\DefaultDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultSerializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Application\CurrentTaskView;
use Ramona\Ras2\Task\Application\HttpApi\GetTasks;
use Ramona\Ras2\Task\Application\Query\Current;
use Ramona\Ras2\Task\Application\Query\Upcoming;
use Ramona\Ras2\Task\Application\Query\WatchedBy;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\User\Application\Session;
use Ramona\Ras2\User\Business\UserId;
use Tests\Ramona\Ras2\EndpointCase;
use Tests\Ramona\Ras2\Task\Mocks\MockCurrentExecutor;
use Tests\Ramona\Ras2\Task\Mocks\MockFindRandomExecutor;
use Tests\Ramona\Ras2\Task\Mocks\MockFindUpcomingExecutor;

final class GetTasksTest extends EndpointCase
{
    public function testThrowsOnMissingAction(): void
    {
        $request = new ServerRequest();

        $controller = new GetTasks(new QueryBus(), new JsonResponseFactory(new DefaultSerializer(
            new DefaultDehydrator(),
            new NullLogger()
        )));

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

        $bus = new QueryBus();
        $result = new TaskView(
            TaskId::generate(),
            'Title',
            UserId::generate(),
            'ramona',
            new ArrayCollection(['tag1', 'tag2']),
            null,
            new ArrayCollection()
        );
        $executor = new MockFindUpcomingExecutor([$result]);

        $bus->installExecutor(Upcoming::class, $executor);
        $serializer = $this->container->get(Serializer::class);

        $controller = new GetTasks($bus, new JsonResponseFactory($serializer));

        $response = ($controller)($request);
        $response->getBody()
            ->seek(0);

        self::assertEquals(
            new Upcoming(123, UserId::fromString('019137b7-d4da-7d6f-9200-400eb263f3fb')),
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
        $request = new ServerRequest(body: new Stream('php://memory', 'rw'), queryParams: [
            'action' => 'current',
        ]);

        $request = $request->withAttribute(
            'session',
            new Session(UserId::fromString('01913d57-1546-79b6-9ecb-9fa6da779199'), 'ramona')
        );

        $bus = new QueryBus();
        $result = new CurrentTaskView(TaskId::generate(), 'Title', new \Safe\DateTimeImmutable(), true);
        $executor = new MockCurrentExecutor($result);

        $bus->installExecutor(Current::class, $executor);
        $serializer = $this->container->get(Serializer::class);

        $controller = new GetTasks($bus, new JsonResponseFactory($serializer));

        $response = ($controller)($request);
        $response->getBody()
            ->seek(0);

        self::assertEquals(
            new Current(UserId::fromString('01913d57-1546-79b6-9ecb-9fa6da779199')),
            $executor->
            query
        );
        self::assertJsonStringEqualsJsonString(
            $serializer->serialize($result),
            $response->getBody()
                ->getContents()
        );
        self::assertEquals('application/json', $response->getHeaderLine('Content-Type'));
    }

    public function testCurrent(): void
    {
        $request = new ServerRequest(queryParams: [
            'limit' => 123,
            'userId' => '01916b6b-7aad-76b3-8c88-1962e83a27d8',
            'action' => 'watched',
        ]);
        $request = $request->withAttribute(
            'session',
            new Session(UserId::fromString('01916b6b-7aad-76b3-8c88-1962e83a27d8'), 'ramona')
        );

        $bus = new QueryBus();
        $result = new TaskView(
            TaskId::generate(),
            'Title',
            UserId::generate(),
            'ramona',
            new ArrayCollection(['tag1', 'tag2']),
            null,
            new ArrayCollection()
        );
        $executor = new MockFindRandomExecutor([$result]);

        $bus->installExecutor(WatchedBy::class, $executor);
        $serializer = $this->container->get(Serializer::class);

        $controller = new GetTasks($bus, new JsonResponseFactory($serializer));

        $response = ($controller)($request);
        $response->getBody()
            ->seek(0);

        self::assertEquals(
            new WatchedBy(UserId::fromString('01916b6b-7aad-76b3-8c88-1962e83a27d8'), 123),
            $executor->query
        );
        self::assertJsonStringEqualsJsonString(
            $serializer->serialize(new ArrayCollection([$result])),
            $response->getBody()
                ->getContents()
        );
        self::assertEquals('application/json', $response->getHeaderLine('Content-Type'));
    }
}
