<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query;

use Psr\Container\ContainerInterface;
use ReflectionClass;

final class DefaultQueryBus implements QueryBus
{
    /**
     * @var array<class-string<Query<mixed>>, Executor<mixed, Query<mixed>>>
     */
    private $executors = [];

    public function __construct(
        private ContainerInterface $container
    ) {

    }

    /**
     * @template TResult
     * @template TQuery of Query<TResult>
     *
     * @param class-string<TQuery> $queryType
     * @param Executor<TResult, TQuery> $executor
     */
    public function installExecutor(string $queryType, Executor $executor): void
    {
        /** @phpstan-ignore assign.propertyType */
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
        $queryClass = get_class($query);

        $executor = $this->executors[$queryClass] ?? null;

        if ($executor === null) {
            $reflectionClass = new ReflectionClass($queryClass);
            foreach ($reflectionClass->getAttributes() as $attribute) {
                if ($attribute->getName() === ExecutedBy::class) {
                    /** @var ExecutedBy $attributeInstance */
                    $attributeInstance = $attribute->newInstance();
                    $executor = $this->container->get($attributeInstance->class);
                }
            }
        }

        if ($executor === null) {
            throw NoExecutor::forQueryClass($queryClass);
        }

        return $executor->execute($query);
    }
}
