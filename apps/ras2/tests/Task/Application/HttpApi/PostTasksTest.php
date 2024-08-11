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
use Ramona\Ras2\Task\Application\Command\FinishWork;
use Ramona\Ras2\Task\Application\Command\PauseWork;
use Ramona\Ras2\Task\Application\Command\StartWork;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;
use Ramona\Ras2\Task\Application\HttpApi\PostTasks;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\User\Application\Session;
use Ramona\Ras2\User\Business\UserId;
use Tests\Ramona\Ras2\EndpointCase;
use Tests\Ramona\Ras2\Task\Mocks\MockExecutor;

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
        $executor = new MockExecutor();
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
        $executor = new MockExecutor();
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

    public function testCanStartWork(): void
    {
        $commandBus = new CommandBus();
        $executor = new MockExecutor();
        $commandBus->installExecutor(StartWork::class, $executor);
        $handler = new PostTasks($commandBus, $this->container->get(Deserializer::class));
        $request = new ServerRequest(method: 'POST', body: new Stream('php://memory', 'rw'), headers: [
            'Content-Type' => 'application/json',
            'X-Action' => 'start-work',
        ]);
        $request = $request->withAttribute(
            'session',
            new Session(UserId::fromString('01913b35-3470-7d9f-b7b9-79f91406d048'), 'ramona')
        );
        $request->getBody()
            ->write('{
                    "taskId": "01913a3e-9bfe-771f-b45b-3093cd7f0dda"
                }');
        $request->getBody()
            ->seek(0);
        $response = ($handler)($request);
        self::assertEquals(
            new StartWork(
                TaskId::fromString('01913a3e-9bfe-771f-b45b-3093cd7f0dda'),
                UserId::fromString('01913b35-3470-7d9f-b7b9-79f91406d048')
            ),
            $executor->command
        );
        self::assertEquals(204, $response->getStatusCode());
    }

    public function testCanPauseWork(): void
    {
        $commandBus = new CommandBus();
        $executor = new MockExecutor();
        $commandBus->installExecutor(PauseWork::class, $executor);
        $handler = new PostTasks($commandBus, $this->container->get(Deserializer::class));
        $request = new ServerRequest(method: 'POST', body: new Stream('php://memory', 'rw'), headers: [
            'Content-Type' => 'application/json',
            'X-Action' => 'pause-work',
        ]);
        $request->getBody()
            ->write('{
                    "taskId": "01913a3e-9bfe-771f-b45b-3093cd7f0dda"
                }');
        $request->getBody()
            ->seek(0);
        $response = ($handler)($request);
        self::assertEquals(
            new PauseWork(TaskId::fromString('01913a3e-9bfe-771f-b45b-3093cd7f0dda')),
            $executor->command
        );
        self::assertEquals(204, $response->getStatusCode());
    }

    public function testCanFinishWork(): void
    {
        $commandBus = new CommandBus();
        $executor = new MockExecutor();
        $commandBus->installExecutor(FinishWork::class, $executor);
        $handler = new PostTasks($commandBus, $this->container->get(Deserializer::class));
        $request = new ServerRequest(method: 'POST', body: new Stream('php://memory', 'rw'), headers: [
            'Content-Type' => 'application/json',
            'X-Action' => 'finish-work',
        ]);
        $request->getBody()
            ->write('{
                    "taskId": "01913a3e-9bfe-771f-b45b-3093cd7f0dda"
                }');
        $request->getBody()
            ->seek(0);
        $response = ($handler)($request);
        self::assertEquals(
            new FinishWork(TaskId::fromString('01913a3e-9bfe-771f-b45b-3093cd7f0dda')),
            $executor->command
        );
        self::assertEquals(204, $response->getStatusCode());
    }
}
