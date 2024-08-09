<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\HttpApi;

use Laminas\Diactoros\Response;
use League\Route\Http\Exception\NotFoundException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Bus;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Query\FindUpcoming;

final class GetTasks
{
    public function __construct(
        private Bus $bus,
        private Serializer $serializer
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $queryParams = $request->getQueryParams();
        if (! array_key_exists('upcoming', $queryParams)) {
            throw new NotFoundException();
        }

        $result = $this->bus->execute(new FindUpcoming());
        $response = new Response(headers: [
            'Content-Type' => 'application/json',
        ]);

        $response->getBody()
            ->write($this->serializer->serialize($result));

        return $response;
    }
}
