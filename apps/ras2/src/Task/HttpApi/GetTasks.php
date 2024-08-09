<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\HttpApi;

use Laminas\Diactoros\Response;
use League\Route\Http\Exception\NotFoundException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Bus;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Query\FindRandom;
use Ramona\Ras2\Task\Query\FindUpcoming;
use Ramona\Ras2\User\UserId;

final class GetTasks
{
    public function __construct(
        private Bus $queryBus,
        private Serializer $serializer
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $queryParams = $request->getQueryParams();
        if (! array_key_exists('action', $queryParams)) {
            throw new NotFoundException();
        }

        switch ($queryParams['action']) {
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
