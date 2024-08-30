<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\QueryExecutor;

final class TaskFormatter
{
    /**
     * @param array<mixed> $rawTask
     * @return array<mixed>
     */
    public static function prepareForHydration(array $rawTask): array
    {
        $rawTask['tags'] = \Safe\json_decode($rawTask['tags'] ?? '[]', true);
        $rawTask['timeRecords'] = \Safe\json_decode($rawTask['time_records'], true);
        $rawTask['assigneeId'] = $rawTask['assignee_id'];
        $rawTask['assigneeName'] = $rawTask['assignee_name'];
        $rawTask['deadline'] = $rawTask['deadline_timestamp'] !== null ? [
            'timestamp' => $rawTask['deadline_timestamp'],
            'timezone' => $rawTask['deadline_timezone'],
        ] : null;

        return $rawTask;
    }
}
