<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Application\HttpApi;

use Doctrine\Common\Collections\ArrayCollection;
use Laminas\Diactoros\ServerRequest;
use Laminas\Diactoros\Stream;
use League\Route\Http\Exception\BadRequestException;
use League\Route\Http\Exception\NotAcceptableException;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultDeserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;
use Ramona\Ras2\Task\Application\HttpApi\PostTasks;
use Ramona\Ras2\Task\Business\TaskId;
use Tests\Ramona\Ras2\EndpointCase;
use Tests\Ramona\Ras2\Task\Mocks\MockUpsertBacklogItemExecutor;
use Tests\Ramona\Ras2\Task\Mocks\MockUpsertIdeaExecutor;

final class PostTasksTest extends EndpointCase
{
    public function testThrowsOnNonJsonRequest(): void
    {
        $handler = new PostTasks(new CommandBus(), new DefaultDeserializer(new Hydrator()));

        $request = new ServerRequest(headers: [
            'Content-Type' => 'text/plain',
        ]);

        $this->expectException(NotAcceptableException::class);
        ($handler)($request);
    }

    public function testThrowsOnUnknownAction(): void
    {
        $handler = new PostTasks(new CommandBus(), new DefaultDeserializer(new Hydrator()));

        $request = new ServerRequest(headers: [
            'Content-Type' => 'application/json',
            'X-Action' => 'inaction',
        ]);

        $this->expectException(BadRequestException::class);
        ($handler)($request);
    }

    public function testCanUpsertIdea(): void
    {
        $commandBus = new CommandBus();
        $executor = new MockUpsertIdeaExecutor();
        $commandBus->installExecutor(UpsertIdea::class, $executor);
        $handler = new PostTasks($commandBus, $this->container->get(Deserializer::class));

        $request = new ServerRequest(method: 'POST', body: new Stream('php://memory', 'rw'), headers: [
            'Content-Type' => 'application/json',
            'X-Action' => 'upsert:idea',
        ]);

        $request->getBody()
            ->write(
                '{
                "id": "01913a3e-9bfe-771f-b45b-3093cd7f0dda",
                "title": "Task title",
                "tags": ["tag", "tag 2"]
            }'
            );
        $request->getBody()
            ->seek(0);

        $response = ($handler)($request);

        self::assertEquals(
            new UpsertIdea(
                TaskId::fromString('01913a3e-9bfe-771f-b45b-3093cd7f0dda'),
                'Task title',
                new ArrayCollection(['tag', 'tag 2'])
            ),
            $executor->command
        );
        self::assertEquals(204, $response->getStatusCode());
    }

    public function testCanUpsertBacklogItem(): void
    {
        $commandBus = new CommandBus();
        $executor = new MockUpsertBacklogItemExecutor();
        $commandBus->installExecutor(UpsertBacklogItem::class, $executor);
        $handler = new PostTasks($commandBus, $this->container->get(Deserializer::class));

        $request = new ServerRequest(method: 'POST', body: new Stream('php://memory', 'rw'), headers: [
            'Content-Type' => 'application/json',
            'X-Action' => 'upsert:backlog-item',
        ]);

        $request->getBody()
            ->write(
                '{
                "id": "01913a3e-9bfe-771f-b45b-3093cd7f0dda",
                "title": "Task title",
                "tags": ["tag", "tag 2"],
                "assignee": null,
                "deadline": null
            }'
            );
        $request->getBody()
            ->seek(0);

        $response = ($handler)($request);

        self::assertEquals(
            new UpsertBacklogItem(
                TaskId::fromString('01913a3e-9bfe-771f-b45b-3093cd7f0dda'),
                'Task title',
                new ArrayCollection(['tag', 'tag 2']),
                null,
                null
            ),
            $executor->command
        );
        self::assertEquals(204, $response->getStatusCode());
    }
}
