<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query;

/**
 * @psalm-suppress UnusedClass
 */
interface QueryBus
{
    /**
     * @template TResult
     * @template TQuery of Query<TResult>
     *
     * @param class-string<TQuery> $queryType
     * @param Executor<TResult, TQuery> $executor
     */
    public function installExecutor(string $queryType, Executor $executor): void;

    /**
     * @psalm-suppress MixedInferredReturnType
     * @psalm-suppress MixedReturnStatement
     * @template TResult
     *
     * @param Query<TResult> $query
     *
     * @return TResult
     */
    public function execute(Query $query): mixed;
}
