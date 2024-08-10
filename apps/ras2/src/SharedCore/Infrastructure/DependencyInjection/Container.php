<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection;

use Psr\Container\ContainerInterface;

class Container implements ContainerInterface
{
    /**
     * @var array<class-string|string, object>
     */
    private array $instances = [];

    /**
     * @param array<class-string, \Closure(Container):object> $factories
     */
    public function __construct(
        private array $factories
    ) {
    }

    /**
     * @template T of object
     * @param class-string<T>|string $id
     * @return ($id is class-string<T> ? T : mixed)
     */
    public function get(string $id)
    {
        if (! isset($this->factories[$id])) {
            throw NotFound::byId($id);
        }

        if (isset($this->instances[$id])) {
            return $this->instances[$id];
        }

        $this->instances[$id] = ($this->factories[$id])($this);
        return $this->instances[$id];
    }

    public function has(string $id): bool
    {
        return isset($this->factories[$id]);
    }
}
