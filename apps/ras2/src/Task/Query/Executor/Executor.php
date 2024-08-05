<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Query\Executor;

use Ramona\Ras2\Task\Query\Query;

/**
 * @template TResult of object
 */
interface Executor
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     * @param Query<TResult> $query
     * @return TResult
     */
    public function execute(Query $query): object;
}
