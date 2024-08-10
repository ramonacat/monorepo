<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use Laminas\Diactoros\Response;
use League\Route\Http\Exception\BadRequestException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\AssertRequest;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;

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
}
