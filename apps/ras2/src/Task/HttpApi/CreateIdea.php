<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\HttpApi;

use Laminas\Diactoros\Response;
use League\Route\Http\Exception\NotAcceptableException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\CQRS\Command\Bus;
use Ramona\Ras2\Serialization\SerializerInterface;

final class CreateIdea
{
    public function __construct(
        private Bus $commandBus,
        private SerializerInterface $serializer
    ) {
    }

    /**
     * @param array<string, scalar> $args
     */
    public function __invoke(ServerRequestInterface $request, array $args): ResponseInterface
    {
        if ($request->getHeaderLine('content-type') !== 'application/json') {
            throw new NotAcceptableException();
        }

        $requestData = $this->serializer->deserialize(
            $request->getBody()
                ->getContents(),
            \Ramona\Ras2\Task\Command\CreateIdea::class,
        );
        $this->commandBus->execute($requestData);

        $response = new Response();
        $response->getBody()
            ->write(print_r($requestData, true) . PHP_EOL . print_r($args, true));

        return $response;
    }
}
