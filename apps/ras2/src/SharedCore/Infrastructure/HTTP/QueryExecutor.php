<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;

interface QueryExecutor
{
    /**
     * @param array<string, class-string<Query<mixed>>> $actionToQueryType
     */
    public function execute(ServerRequestInterface $request, array $actionToQueryType): ResponseInterface;
}
