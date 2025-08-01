<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Infrastructure;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;
use Ramona\Ras2\System\Business\NixOS;
use Ramona\Ras2\System\Business\OperatingSystem;
use Ramona\Ras2\System\Business\System;
use Ramona\Ras2\System\Business\SystemId;
use RuntimeException;

/**
 * @implements ValueHydrator<System>
 */
final class SystemHydrator implements ValueHydrator
{
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): System
    {
        return new System(
            $hydrator->hydrate(SystemId::class, $input['id']),
            $input['hostname'],
            $hydrator->hydrate($this->systemNameToType($input['operatingSystemType']), $input['operatingSystem']),
            ($input['latestPing'] ?? null) === null ? null : $hydrator->hydrate(
                \Safe\DateTimeImmutable::class,
                $input['latestPing']
            ),
        );
    }

    /**
     * @return class-string<System>
     */
    public function handles(): string
    {
        return System::class;
    }

    /**
     * @return class-string<OperatingSystem>
     */
    private function systemNameToType(string $operatingSystemName): string
    {
        return match ($operatingSystemName) {
            'NIXOS' => NixOS::class,
            default => throw new RuntimeException('Invalid system name ' . $operatingSystemName)
        };
    }
}
