<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\QueryExecutor;
use Ramona\Ras2\Task\Application\Query\Current;
use Ramona\Ras2\Task\Application\Query\Upcoming;
use Ramona\Ras2\Task\Application\Query\WatchedBy;

final class GetTasks
{
    public function __construct(
        private QueryExecutor $queryExecutor
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        return $this->queryExecutor->execute(
            $request,
            [
                'upcoming' => Upcoming::class,
                'watched' => WatchedBy::class,
                'current' => Current::class,
            ]
        );
    }
}
