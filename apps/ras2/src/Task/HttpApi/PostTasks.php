<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\HttpApi;

use Laminas\Diactoros\Response;
use League\Route\Http\Exception\BadRequestException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Bus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\AssertRequest;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\Task\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Command\UpsertIdea;

final class PostTasks
{
    public function __construct(
        private Bus $commandBus,
        private Deserializer $deserializer
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        AssertRequest::isJson($request);

        $requestedAction = $request->getHeaderLine('X-Action');
        if ($requestedAction === 'upsert:idea') {
            return $this->upsertIdea($request);
        } elseif ($requestedAction === 'upsert:backlog-item') {
            return $this->upsertBacklogItem($request);
        }

        throw new BadRequestException();
    }

    public function upsertIdea(ServerRequestInterface $request): Response\EmptyResponse
    {
        $requestData = $this->deserializer->deserialize(UpsertIdea::class, $request->getBody() ->getContents());
        $this->commandBus->execute($requestData);

        return new Response\EmptyResponse(204);
    }

    public function upsertBacklogItem(ServerRequestInterface $request): ResponseInterface
    {
        $requestData = $this->deserializer->deserialize(UpsertBacklogItem::class, $request->getBody()->getContents());
        $this->commandBus->execute($requestData);

        return new Response\EmptyResponse(204);
    }
}
