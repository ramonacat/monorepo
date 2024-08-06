<?php

declare(strict_types=1);

namespace Ramona\Ras2\CQRS\Query;

/**
 * @template TResult
 * @template TQuery of Query<TResult>
 */
interface Executor
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     * @param TQuery $query
     * @return TResult
     */
    public function execute(Query $query): mixed;
}
