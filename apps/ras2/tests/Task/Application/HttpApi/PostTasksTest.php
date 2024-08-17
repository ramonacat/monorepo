<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Application\HttpApi;

use Doctrine\Common\Collections\ArrayCollection;
use Laminas\Diactoros\ServerRequest;
use Laminas\Diactoros\Stream;
use League\Route\Http\Exception\BadRequestException;
use League\Route\Http\Exception\NotAcceptableException;
use PHPUnit\Framework\Attributes\DataProvider;
use Psr\Log\NullLogger;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultDeserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\Task\Application\Command\FinishWork;
use Ramona\Ras2\Task\Application\Command\PauseWork;
use Ramona\Ras2\Task\Application\Command\ReturnToBacklog;
use Ramona\Ras2\Task\Application\Command\StartWork;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;
use Ramona\Ras2\Task\Application\HttpApi\PostTasks;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\User\Business\UserId;
use Tests\Ramona\Ras2\EndpointCase;
use Tests\Ramona\Ras2\Task\Mocks\MockExecutor;

final class PostTasksTest extends EndpointCase
{
    public function testThrowsOnNonJsonRequest(): void
    {
        $handler = new PostTasks(new CommandBus(), new DefaultDeserializer(new Hydrator(), new NullLogger()));

        $request = new ServerRequest(headers: [
            'Content-Type' => 'text/plain',
        ]);

        $this->expectException(NotAcceptableException::class);
        ($handler)($request);
    }

    public function testThrowsOnUnknownAction(): void
    {
        $handler = new PostTasks(new CommandBus(), new DefaultDeserializer(new Hydrator(), new NullLogger()));

        $request = new ServerRequest(headers: [
            'Content-Type' => 'application/json',
            'X-Action' => 'inaction',
        ]);

        $this->expectException(BadRequestException::class);
        ($handler)($request);
    }

    /**
     * @return iterable<array{0:Command,1:string,2:string}>
     */
    public static function dataCanExecuteCommand(): iterable
    {
        yield [
            new UpsertIdea(
                TaskId::fromString('01913a3e-9bfe-771f-b45b-3093cd7f0dda'),
                'Task title',
                new ArrayCollection(['tag', 'tag 2'])
            ),
            'upsert:idea',
            '{
                "id": "01913a3e-9bfe-771f-b45b-3093cd7f0dda",
                "title": "Task title",
                "tags": ["tag", "tag 2"]
            }',
        ];
        yield [
            new UpsertBacklogItem(
                TaskId::fromString('01913a3e-9bfe-771f-b45b-3093cd7f0dda'),
                'Task title',
                new ArrayCollection(['tag', 'tag 2']),
                null,
                null
            ),
            'upsert:backlog-item',
            '{
                "id": "01913a3e-9bfe-771f-b45b-3093cd7f0dda",
                "title": "Task title",
                "tags": ["tag", "tag 2"],
                "assignee": null,
                "deadline": null
            }',
        ];

        yield [
            new StartWork(
                TaskId::fromString('01913a3e-9bfe-771f-b45b-3093cd7f0dda'),
                UserId::fromString('01913b35-3470-7d9f-b7b9-79f91406d048')
            ),
            'start-work',
            '{
                "taskId": "01913a3e-9bfe-771f-b45b-3093cd7f0dda",
                "userId": "01913b35-3470-7d9f-b7b9-79f91406d048"
            }',
        ];

        yield [
            new PauseWork(TaskId::fromString('01913a3e-9bfe-771f-b45b-3093cd7f0dda')),
            'pause-work',
            '{"taskId": "01913a3e-9bfe-771f-b45b-3093cd7f0dda"}',
        ];

        yield [
            new FinishWork(
                TaskId::fromString('01913a3e-9bfe-771f-b45b-3093cd7f0dda'),
                UserId::fromString('01913b35-3470-7d9f-b7b9-79f91406d048')
            ),
            'finish-work',
            '{
                "taskId": "01913a3e-9bfe-771f-b45b-3093cd7f0dda",
                "userId": "01913b35-3470-7d9f-b7b9-79f91406d048"
            }',
        ];

        yield [
            new ReturnToBacklog(TaskId::fromString('01913a3e-9bfe-771f-b45b-3093cd7f0dda')),
            'return-to-backlog',
            '{"taskId": "01913a3e-9bfe-771f-b45b-3093cd7f0dda"}',
        ];
    }

    #[DataProvider('dataCanExecuteCommand')]
    public function testCanExecuteCommand(Command $expectedCommand, string $actionName, string $requestBody): void
    {
        $commandBus = new CommandBus();
        $executor = new MockExecutor();
        $commandBus->installExecutor(get_class($expectedCommand), $executor);
        $handler = new PostTasks($commandBus, $this->container->get(Deserializer::class));
        $request = new ServerRequest(method: 'POST', body: new Stream('php://memory', 'rw'), headers: [
            'Content-Type' => 'application/json',
            'X-Action' => $actionName,
        ]);
        $request->getBody()
            ->write($requestBody);
        $request->getBody()
            ->seek(0);
        $response = ($handler)($request);
        self::assertEquals($expectedCommand, $executor->command);
        self::assertEquals(204, $response->getStatusCode());
    }
}
