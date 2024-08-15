<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Application\HttpApi;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\Event\Application\Query\InMonth;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;

final readonly class GetEvents
{
    public function __construct(
        private QueryBus $queryBus,
        private JsonResponseFactory $responseFactory
    ) {
    }

    public function __invoke(ServerRequestInterface $serverRequest): ResponseInterface
    {
        $query = $serverRequest->getQueryParams();

        $year = (int) $query['year'];
        $month = (int) $query['month'];

        $results = $this->queryBus->execute(new InMonth($year, $month, new \DateTimeZone('Europe/Warsaw')));

        return $this->responseFactory->create($results);
    }
}
