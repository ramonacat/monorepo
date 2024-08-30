<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Business\Filter;

final readonly class PostgresFilterRepository implements FilterRepository
{
    public function __construct(
        private Connection $connection,
        private Serializer $serializer
    ) {
    }

    public function upsert(Filter $filter): void
    {
        $this->connection->executeStatement('
            INSERT INTO tasks_filters(id, name, assignee_ids, tags_ids) 
                VALUES (:id, :name, :assignee_ids, :tags_ids)
            ON CONFLICT(id) DO UPDATE SET name=:name, assignee_ids=:assignee_ids, tags_ids=:tags_ids
        ', [
            'id' => $filter->id(),
            'name' => $filter->name(),
            'assignee_ids' => $this->serializer->serialize($filter->assignees()),
            'tags_ids' => $this->serializer->serialize($filter->tags()),
        ]);
    }
}
