<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Application\HttpApi;

use Laminas\Diactoros\Response\EmptyResponse;
use League\Route\Http\Exception\NotFoundException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\Event\Application\Command\UpsertEvent;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\AssertRequest;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;

final readonly class PostEvents
{
    public function __construct(
        private Deserializer $deserializer,
        private CommandBus $commandBus,
    ) {

    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        AssertRequest::isJson($request);

        $requestedAction = $request->getHeaderLine('X-Action');

        return match ($requestedAction) {
            'upsert' => $this->upsert($request),
            default => throw new NotFoundException()
        };
    }

    private function upsert(ServerRequestInterface $request): ResponseInterface
    {
        $command = $this->deserializer->deserialize(UpsertEvent::class, $request->getBody()->getContents());
        $this->commandBus->execute($command);

        return new EmptyResponse();
    }
}
