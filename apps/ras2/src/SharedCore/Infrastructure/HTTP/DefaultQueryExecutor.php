<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use League\Route\Http\Exception\NotFoundException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

final class DefaultQueryExecutor implements QueryExecutor
{
    public function __construct(
        private Hydrator $hydrator,
        private QueryBus $queryBus,
        private DefaultJsonResponseFactory $jsonResponseFactory
    ) {
    }

    public function execute(ServerRequestInterface $request, array $actionToQueryType): ResponseInterface
    {
        $queryString = $request->getQueryParams();
        $action = $queryString['action'] ?? throw new NotFoundException();
        $queryType = $actionToQueryType[$action] ?? throw new NotFoundException();

        $query = $this->hydrator->hydrate($queryType, $queryString);
        $result = $this->queryBus->execute($query);

        return $this->jsonResponseFactory->create($result);
    }
}
