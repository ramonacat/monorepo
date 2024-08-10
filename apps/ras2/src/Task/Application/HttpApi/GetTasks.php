<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use Laminas\Diactoros\Response;
use League\Route\Http\Exception\NotFoundException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Application\Query\Current;
use Ramona\Ras2\Task\Application\Query\Random;
use Ramona\Ras2\Task\Application\Query\Upcoming;
use Ramona\Ras2\User\Application\Session;
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
                return $this->getUpcoming($queryParams);
            case 'watched':
                return $this->getWatched((int) $queryParams['limit']);
            case 'current':
                return $this->getCurrent($request);
            default:
                throw new NotFoundException();
        }
    }

    private function getWatched(int $limit): Response
    {
        // TODO we don't have the concept of "watched tags" yet, but once we do, this will have to be adjusted
        $result = $this->queryBus->execute(new Random($limit));
        $response = new Response(headers: [
            'Content-Type' => 'application/json',
        ]);

        $response->getBody()
            ->write($this->serializer->serialize($result));

        return $response;
    }

    /** @psalm-suppress MixedArgument
     * @param array<mixed> $queryParams
     */
    private function getUpcoming(array $queryParams): Response
    {
        $assigneeId = isset($queryParams['assigneeId'])
            ? UserId::fromString($queryParams['assigneeId'])
            : null;

        $result = $this->queryBus->execute(new Upcoming((int) $queryParams['limit'], $assigneeId));

        $response = new Response(headers: [
            'Content-Type' => 'application/json',
        ]);

        $response->getBody()
            ->write($this->serializer->serialize($result));
        return $response;
    }

    private function getCurrent(ServerRequestInterface $request): ResponseInterface
    {
        /** @var Session $session */
        $session = $request->getAttribute(RequireLogin::SESSION_ATTRIBUTE);
        $query = new Current($session->userId);

        $result = $this->queryBus->execute($query);
        $response = new Response(headers: [
            'Content-Type' => 'application/json',
        ]);

        $response->getBody()
            ->write($this->serializer->serialize($result));
        return $response;
    }
}
