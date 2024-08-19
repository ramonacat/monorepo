<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Infrastructure;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\System\Business\NixOS;
use Ramona\Ras2\System\Business\OperatingSystem;
use Ramona\Ras2\System\Business\System;

final class PostgresRepository implements Repository
{
    public function __construct(
        private Connection $connection,
        private Serializer $serializer,
        private Hydrator $hydrator
    ) {
    }

    public function insert(System $system): void
    {
        $this->connection->executeStatement('
            INSERT INTO systems(id, hostname, operating_system, operating_system_type) 
                VALUES (:id, :hostname, :operating_system, :operating_system_type)
        ', [
            'id' => (string) $system->id(),
            'hostname' => $system->hostname(),
            'operating_system' => $this->serializer->serialize($system->operatingSystem()),
            'operating_system_type' => $this->nameForOperatingSystemType($system->operatingSystem()),
        ]);
    }

    public function save(System $system): void
    {
        $this->connection->executeStatement('
            INSERT INTO systems(id, hostname, operating_system_type, operating_system) 
                VALUES (:id, :hostname, :operating_system_type, :operating_system)
                ON CONFLICT(id) 
                    DO UPDATE SET hostname=:hostname, operating_system=:operating_system, operating_system_type=:operating_system_type
        ', [
            'id' => (string) $system->id(),
            'hostname' => $system->hostname(),
            'operating_system' => $this->serializer->serialize($system->operatingSystem()),
            'operating_system_type' => $this->nameForOperatingSystemType($system->operatingSystem()),
        ]);
    }

    public function getByHostname(string $hostname): System
    {
        $system = $this->connection->fetchAssociative('
            SELECT 
                id, hostname, operating_system_type, operating_system 
            FROM systems
        ');

        if ($system === false) {
            throw new \RuntimeException('System not found by hostname: "' . $hostname . '"');
        }

        $system['operatingSystem'] = \Safe\json_decode($system['operating_system'], true);
        $system['operatingSystemType'] = $system['operating_system_type'];

        return $this->hydrator->hydrate(System::class, $system);
    }

    public function transactional(\Closure $param): void
    {
        $this->connection->transactional($param);
    }

    private function nameForOperatingSystemType(OperatingSystem $operatingSystem): string
    {
        if ($operatingSystem instanceof NixOS) {
            return 'NIXOS';
        }

        throw new \RuntimeException('Unknown operating system type: ' . get_class($operatingSystem));
    }
}
