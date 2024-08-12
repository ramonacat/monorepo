<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use Laminas\Diactoros\Response;
use League\Route\Http\Exception\BadRequestException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\AssertRequest;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\Task\Application\Command\FinishWork;
use Ramona\Ras2\Task\Application\Command\PauseWork;
use Ramona\Ras2\Task\Application\Command\ReturnToBacklog;
use Ramona\Ras2\Task\Application\Command\StartWork;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;

final readonly class PostTasks
{
    public function __construct(
        private CommandBus $commandBus,
        private Deserializer $deserializer
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        AssertRequest::isJson($request);

        $requestedAction = $request->getHeaderLine('X-Action');

        return match ($requestedAction) {
            'upsert:idea' => $this->executeCommand(UpsertIdea::class, $request),
            'upsert:backlog-item' => $this->executeCommand(UpsertBacklogItem::class, $request),
            'start-work' => $this->executeCommand(StartWork::class, $request),
            'pause-work' => $this->executeCommand(PauseWork::class, $request),
            'finish-work' => $this->executeCommand(FinishWork::class, $request),
            'return-to-backlog' => $this->executeCommand(ReturnToBacklog::class, $request),
            default => throw new BadRequestException()
        };
    }

    /**
     * @template T of Command
     * @param class-string<T> $name
     */
    private function executeCommand(string $name, ServerRequestInterface $request): ResponseInterface
    {
        $command = $this->deserializer->deserialize($name, $request->getBody()->getContents());
        $this->commandBus->execute($command);
        return new Response\EmptyResponse(204);
    }
}
