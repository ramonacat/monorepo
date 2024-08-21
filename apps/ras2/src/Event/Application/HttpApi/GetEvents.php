<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Application\HttpApi;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\Event\Application\Query\InMonth;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\QueryExecutor;

final readonly class GetEvents
{
    public function __construct(
        private QueryExecutor $queryExecutor
    ) {
    }

    public function __invoke(ServerRequestInterface $serverRequest): ResponseInterface
    {
        return $this->queryExecutor->execute($serverRequest, [
            'in-month' => InMonth::class,
        ]);
    }
}
