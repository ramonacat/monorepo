<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query;

#[\Attribute(\Attribute::TARGET_CLASS)]
final readonly class ExecutedBy
{
    /**
     * @template T1
     * @template T2 of Query<T1>
     * @param class-string<Executor<T1, T2>> $class
     */
    public function __construct(
        public string $class
    ) {
    }
}
