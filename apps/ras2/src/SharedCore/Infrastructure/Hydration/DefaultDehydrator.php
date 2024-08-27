<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\ObjectDehydrator;

final class DefaultDehydrator implements Dehydrator
{
    /**
     * @var array<string, ValueDehydrator<mixed>>
     */
    private array $valueDehydrators = [];

    public function __construct()
    {
    }

    public function installValueDehydrator(ValueDehydrator $valueDehydrator): void
    {
        $this->valueDehydrators[$valueDehydrator->handles()] = $valueDehydrator;
    }

    public function dehydrate(mixed $value): mixed
    {
        $typeName = is_object($value) ? get_class($value) : gettype($value);

        if (is_object($value)) {
            $alternativePaths = [$typeName];

            $parentClass = get_class($value);
            while (($parentClass = get_parent_class($parentClass)) !== false) {
                $alternativePaths[] = $parentClass;
            }

            $classReflection = new \ReflectionClass($value);
            $alternativePaths = [...$alternativePaths, ...$classReflection->getInterfaceNames()];

            $found = false;

            foreach ($alternativePaths as $alternativePath) {
                if (isset($this->valueDehydrators[$alternativePath])) {
                    $typeName = $alternativePath;
                    $found = true;
                    break;
                }
            }

            if (! $found) {
                if (! class_exists($typeName)) {
                    throw CannotDehydrateType::for($typeName);
                }
                $this->valueDehydrators[$typeName] = new ObjectDehydrator($typeName);

            }
        } else {
            if (! isset($this->valueDehydrators[$typeName])) {
                throw CannotDehydrateType::for($typeName);
            }
        }

        return $this
            ->valueDehydrators[$typeName]
            ->dehydrate($this, $value);
    }
}
