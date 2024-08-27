<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ObjectHydrator;
use Ramona\Ras2\User\Application\Session;

final class DefaultHydrator implements Hydrator
{
    /**
     * @var array<string, ValueHydrator<mixed>>
     */
    private array $valueHydrators = [];

    private ?Session $session = null;

    public function installValueHydrator(ValueHydrator $valueHydrator): void
    {
        $this->valueHydrators[$valueHydrator->handles()] = $valueHydrator;
    }

    public function hydrate(string $targetType, mixed $input, array $attributes = []): mixed
    {
        if ($targetType === 'int') {
            $targetType = 'integer';
        } elseif ($targetType === 'bool') {
            $targetType = 'boolean';
        }

        if (! isset($this->valueHydrators[$targetType])) {
            if (class_exists($targetType)) {
                $this->valueHydrators[$targetType] = new ObjectHydrator($targetType);
            } else {
                throw CannotHydrateType::for($targetType);
            }
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
