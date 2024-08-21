<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

use Ramona\Ras2\User\Application\Session;

final class Hydrator
{
    /**
     * @var array<string, ValueHydrator<mixed>>
     */
    private array $valueHydrators = [];

    private ?Session $session = null;

    /**
     * @template T
     * @param ValueHydrator<T> $valueHydrator
     */
    public function installValueHydrator(ValueHydrator $valueHydrator): void
    {
        $this->valueHydrators[$valueHydrator->handles()] = $valueHydrator;
    }

    /**
     * @template T
     *
     * @param class-string<T>|'float'|'integer'|'int'|'bool'|'string'|'array'|'boolean'|'resource'|'NULL' $targetType
     * @param list<HydrationAttribute> $attributes
     * @return T
     */
    public function hydrate(string $targetType, mixed $input, array $attributes = []): mixed
    {
        if ($targetType === 'int') {
            $targetType = 'integer';
        } elseif ($targetType === 'bool') {
            $targetType = 'boolean';
        }

        if (! isset($this->valueHydrators[$targetType])) {
            throw CannotHydrateType::for($targetType);
        }

        return $this->valueHydrators[$targetType]->hydrate($this, $input, $attributes);
    }

    public function setSession(?Session $session): void
    {
        $this->session = $session;
    }

    public function session(): ?Session
    {
        return $this->session;
    }
}
