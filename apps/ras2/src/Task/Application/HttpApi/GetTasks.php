<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use League\Route\Http\Exception\NotFoundException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\Task\Application\Query\Current;
use Ramona\Ras2\Task\Application\Query\Upcoming;
use Ramona\Ras2\Task\Application\Query\WatchedBy;
use Ramona\Ras2\User\Application\Session;
use Ramona\Ras2\User\Business\UserId;

final class GetTasks
{
    public function __construct(
        private QueryBus $queryBus,
        private JsonResponseFactory $responseFactory
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $queryParams = $request->getQueryParams();
        /** @var Session $session */
        $session = $request->getAttribute(RequireLogin::SESSION_ATTRIBUTE);

        switch ($queryParams['action'] ?? null) {
            case 'upcoming':
                return $this->getUpcoming($queryParams);
            case 'watched':
                return $this->getWatched((int) $queryParams['limit'], $session->userId);
            case 'current':
                return $this->getCurrent($request);
            default:
                throw new NotFoundException();
        }
    }

    private function getWatched(int $limit, UserId $userId): ResponseInterface
    {
        $result = $this->queryBus->execute(new WatchedBy($userId, $limit));
        return $this->responseFactory->create($result);
    }

    /** @psalm-suppress MixedArgument
     * @param array<mixed> $queryParams
     */
    private function getUpcoming(array $queryParams): ResponseInterface
    {
        $assigneeId = isset($queryParams['assigneeId'])
            ? UserId::fromString($queryParams['assigneeId'])
            : null;

        $result = $this->queryBus->execute(new Upcoming((int) $queryParams['limit'], $assigneeId));

        return $this->responseFactory->create($result);
    }

    private function getCurrent(ServerRequestInterface $request): ResponseInterface
    {
        /** @var Session $session */
        $session = $request->getAttribute(RequireLogin::SESSION_ATTRIBUTE);
        $query = new Current($session->userId);

        $result = $this->queryBus->execute($query);
        return $this->responseFactory->create($result);
    }
}
