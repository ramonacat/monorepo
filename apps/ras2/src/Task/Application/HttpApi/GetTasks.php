<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use Laminas\Diactoros\Response;
use League\Route\Http\Exception\NotFoundException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Application\Query\FindRandom;
use Ramona\Ras2\Task\Application\Query\FindUpcoming;
use Ramona\Ras2\User\Business\UserId;

final class GetTasks
{
    public function __construct(
        private QueryBus $queryBus,
        private Serializer $serializer
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $queryParams = $request->getQueryParams();

        switch ($queryParams['action'] ?? null) {
            case 'upcoming':
                /** @psalm-suppress MixedArgument */
                $assigneeId = isset($queryParams['assigneeId'])
                    ? UserId::fromString($queryParams['assigneeId'])
                    : null;

                $result = $this->queryBus->execute(new FindUpcoming((int) $queryParams['limit'], $assigneeId));

                $response = new Response(headers: [
                    'Content-Type' => 'application/json',
                ]);

                $response->getBody()
                    ->write($this->serializer->serialize($result));

                return $response;
            case 'watched':
                // TODO we don't have the concept of "watched tags" yet, but once we do, this will have to be adjusted
                $limit = (int) $queryParams['limit'];
                $result = $this->queryBus->execute(new FindRandom($limit));
                $response = new Response(headers: [
                    'Content-Type' => 'application/json',
                ]);

                $response->getBody()
                    ->write($this->serializer->serialize($result));

                return $response;
            default:
                throw new NotFoundException();
        }
    }
}
