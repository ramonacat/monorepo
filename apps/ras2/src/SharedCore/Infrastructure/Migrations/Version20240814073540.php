<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20240814073540 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Create a table for events';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            CREATE TYPE datetime_with_timezone AS (
                "datetime" TIMESTAMP,
                "timezone" TEXT
            );
        ');
        $this->addSql('
            CREATE TABLE events (
                "id" UUID PRIMARY KEY, 
                "title" TEXT,
                "start" datetime_with_timezone NOT NULL,
                "end" datetime_with_timezone NOT NULL
            );
        ');
        $this->addSql('
            CREATE TABLE event_attendees (
                "event_id" UUID REFERENCES events(id),
                "attendee_id" UUID REFERENCES users(id),
                
                PRIMARY KEY (event_id, attendee_id)
            );
        ');
    }
}
