<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Infrastructure\QueryExecutor;

use DateTimeZone;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Ramona\Ras2\Event\Application\EventView;
use Ramona\Ras2\Event\Application\Query\InMonth;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Safe\DateTimeImmutable;

/**
 * @implements Executor<ArrayCollection<int, EventView>, InMonth>
 */
final class InMonthExecutor implements Executor
{
    public function __construct(
        private Connection $connection,
        private Hydrator $hydrator
    ) {
    }

    public function execute(Query $query): mixed
    {
        $start = new DateTimeImmutable($query->year . '-' . $query->month . '-01', $query->timeZone);
        $end = $start->setDate($query->year, $query->month, (int) $start->format('t'));

        $rows = $this->connection->fetchAllAssociative(
            '
                SELECT
                    id, 
                    title, 
                    start,
                    "end",
                    (SELECT json_agg(u.name) FROM event_attendees ea INNER JOIN users u ON ea.attendee_id = u.id) AS attendee_usernames
                FROM events
                WHERE 
                    ((start).datetime AT TIME ZONE (start).timezone AT TIME ZONE \'UTC\')
                    BETWEEN
                        :start AND :end
            ',
            [
                'start' => $start->setTimezone(new DateTimeZone('UTC'))
                    ->format('Y-m-d H:i:s'),
                'end' => $end->setTimezone(new DateTimeZone('UTC'))
                    ->format('Y-m-d H:i:s'),
            ]
        );

        $rows = array_map(function ($row) {
            $row['start'] = $this->convertDateTimeFromDatabase($row['start']);
            $row['end'] = $this->convertDateTimeFromDatabase($row['end']);
            $row['attendeeUsernames'] = \Safe\json_decode($row['attendee_usernames'] ?? '[]');
            unset($row['attendee_usernames']);

            return $row;
        }, $rows);
        $result = array_map(fn ($row) => $this->hydrator->hydrate(EventView::class, $row), $rows);

        return new ArrayCollection($result);
    }

    /**
     * @return array{timestamp:string, timezone: string}
     */
    private function convertDateTimeFromDatabase(string $raw): array
    {
        \Safe\preg_match('/\(\"(?<timestamp>.*?)\",(?<timezone>.*?)\)/S', $raw, $matches);

        return [
            'timestamp' => $matches['timestamp'],
            'timezone' => $matches['timezone'],
        ];
    }
}
