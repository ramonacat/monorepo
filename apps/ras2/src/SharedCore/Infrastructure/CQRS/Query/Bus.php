<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query;

/**
 * @psalm-suppress UnusedClass
 */
final class Bus
{
    /**
     * @var array<class-string<Query<mixed>>, Executor<mixed, Query<mixed>>>
     */
    private $executors = [];

    /**
     * @template TResult
     * @template TQuery of Query<TResult>
     *
     * @param class-string<TQuery> $queryType
     * @param Executor<TResult, TQuery> $executor
     */
    public function installExecutor(string $queryType, Executor $executor): void
    {
        $this->executors[$queryType] = $executor;
    }

    /**
     * @psalm-suppress MixedInferredReturnType
     * @psalm-suppress MixedReturnStatement
     * @template TResult
     *
     * @param Query<TResult> $query
     *
     * @return TResult
     */
    public function execute(Query $query): mixed
    {
        /** @phpstan-assert Executor<TResult, Query<TResult>> $executor
         * @psalm-assert Executor<TResult, Query<TResult>> $executor
         */
        $executor = $this->executors[get_class($query)];
        return $executor->execute($query);
    }
}
