<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command;

#[\Attribute(\Attribute::TARGET_CLASS)]
final readonly class ExecutedBy
{
    /**
     * @template T of Command
     * @param class-string<Executor<T>> $class
     */
    public function __construct(
        public string $class
    ) {
    }
}
