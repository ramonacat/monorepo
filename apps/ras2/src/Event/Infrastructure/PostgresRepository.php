<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Infrastructure;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\Event\Business\Event;

final class PostgresRepository implements Repository
{
    public function __construct(
        private Connection $connection
    ) {
    }

    public function save(Event $event): void
    {
        $eventStartTimezone = $event->start()
            ->getTimezone();
        $eventEndTimezone = $event->end()
            ->getTimezone();

        $this->connection->executeQuery('
            INSERT INTO events(id, title, start, "end") 
            VALUES (
                    :id, 
                    :title, 
                    (:start_datetime, :start_timezone),
                    (:end_datetime, :end_timezone)
                )
            ON CONFLICT (id) DO UPDATE 
                SET 
                    title=:title, 
                    start=(:start_datetime, :start_timezone), 
                    "end"=(:end_datetime, :end_timezone)
        ', [
            'id' => (string) $event->id(),
            'title' => $event->title(),
            'start_datetime' => $event->start()
                ->format('Y-m-d H:i:s'),
            'start_timezone' => $event->start()
                ->getTimezone()
                ->getName(),
            'end_datetime' => $event->start()
                ->format('Y-m-d H:i:s'),
            'end_timezone' => $event->start()
                ->getTimezone()
                ->getName(),
        ]);
    }
}
