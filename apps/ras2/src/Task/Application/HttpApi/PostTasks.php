<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use Laminas\Diactoros\Response;
use League\Route\Http\Exception\BadRequestException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\AssertRequest;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\Task\Application\Command\FinishWork;
use Ramona\Ras2\Task\Application\Command\PauseWork;
use Ramona\Ras2\Task\Application\Command\StartWork;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;
use Ramona\Ras2\User\Application\Session;

final class PostTasks
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
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
            'upsert:idea' => $this->upsertIdea($request),
            'upsert:backlog-item' => $this->upsertBacklogItem($request),
            'start-work' => $this->startWork($request),
            'pause-work' => $this->pauseWork($request),
            'finish-work' => $this->finishWork($request),
            default => throw new BadRequestException()
        };
    }

    private function upsertIdea(ServerRequestInterface $request): Response\EmptyResponse
    {
        $requestData = $this->deserializer->deserialize(UpsertIdea::class, $request->getBody() ->getContents());
        $this->commandBus->execute($requestData);

        return new Response\EmptyResponse(204);
    }

    private function upsertBacklogItem(ServerRequestInterface $request): ResponseInterface
    {
        $requestData = $this->deserializer->deserialize(UpsertBacklogItem::class, $request->getBody()->getContents());
        $this->commandBus->execute($requestData);

        return new Response\EmptyResponse(204);
    }

    private function startWork(ServerRequestInterface $request): ResponseInterface
    {
        $requestData = $this->deserializer->deserialize(StartWorkRequest::class, $request->getBody()->getContents());

        $session = $request->getAttribute(RequireLogin::SESSION_ATTRIBUTE);
        assert($session instanceof Session);

        $this->commandBus->execute(new StartWork($requestData->taskId, $session->userId));

        return new Response\EmptyResponse(204);
    }

    private function pauseWork(ServerRequestInterface $request): ResponseInterface
    {
        $requestData = $this->deserializer->deserialize(PauseWork::class, $request->getBody()->getContents());

        $this->commandBus->execute($requestData);

        return new Response\EmptyResponse(204);
    }

    private function finishWork(ServerRequestInterface $request): ResponseInterface
    {
        $command = $this->deserializer->deserialize(FinishWork::class, $request->getBody()->getContents());

        $this->commandBus->execute($command);

        return new Response\EmptyResponse(204);
    }
}
