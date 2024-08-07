<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\HttpApi;

use Laminas\Diactoros\Response\EmptyResponse;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\CQRS\Command\Bus;
use Ramona\Ras2\HTTP\AssertRequest;
use Ramona\Ras2\Serialization\SerializerInterface;

final class CreateUser
{
    public function __construct(
        private Bus $commandBus,
        private SerializerInterface $serializer
    ) {
    }

    public function __invoke(ServerRequestInterface $serverRequest): ResponseInterface
    {
        AssertRequest::isJson($serverRequest);

        $command = $this->serializer->deserialize(
            $serverRequest->getBody()
                ->getContents(),
            \Ramona\Ras2\User\Command\UpsertUser::class
        );

        $this->commandBus->execute($command);

        return new EmptyResponse();
    }
}
