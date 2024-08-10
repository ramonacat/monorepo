<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection;

final class ContainerBuilder
{
    /**
     * @var array<class-string, \Closure(Container):object>
     */
    private array $factories = [];

    /**
     * @template T of object
     * @param class-string<T> $type
     * @param callable(Container):T $factory
     */
    public function register(string $type, callable $factory): void
    {
        $this->factories[$type] = ($factory)(...);
    }

    public function build(): Container
    {
        return new Container($this->factories);
    }
}
