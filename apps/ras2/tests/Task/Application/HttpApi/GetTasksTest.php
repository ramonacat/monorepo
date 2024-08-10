<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Application\HttpApi;

use Doctrine\Common\Collections\ArrayCollection;
use Laminas\Diactoros\ServerRequest;
use League\Route\Http\Exception\NotFoundException;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\DefaultDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultSerializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Application\HttpApi\GetTasks;
use Ramona\Ras2\Task\Application\Query\FindRandom;
use Ramona\Ras2\Task\Application\Query\FindUpcoming;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\User\Business\UserId;
use Tests\Ramona\Ras2\EndpointCase;
use Tests\Ramona\Ras2\Task\Mocks\MockFindRandomExecutor;
use Tests\Ramona\Ras2\Task\Mocks\MockFindUpcomingExecutor;

final class GetTasksTest extends EndpointCase
{
    public function testThrowsOnMissingAction(): void
    {
        $request = new ServerRequest();

        $controller = new GetTasks(new QueryBus(), new DefaultSerializer(new DefaultDehydrator()));

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
        $result = new TaskView(TaskId::generate(), 'Title', 'ramona', new ArrayCollection(['tag1', 'tag2']), null);
        $executor = new MockFindUpcomingExecutor([$result]);

        $bus->installExecutor(FindUpcoming::class, $executor);
        $serializer = $this->container->get(Serializer::class);

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

        $bus = new QueryBus();
        $result = new TaskView(TaskId::generate(), 'Title', 'ramona', new ArrayCollection(['tag1', 'tag2']), null);
        $executor = new MockFindRandomExecutor([$result]);

        $bus->installExecutor(FindRandom::class, $executor);
        $serializer = $this->container->get(Serializer::class);

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
