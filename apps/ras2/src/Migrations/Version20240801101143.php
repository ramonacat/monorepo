<?php

declare(strict_types=1);

namespace Ramona\Ras2\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * @psalm-suppress UnusedClass
 */
final class Version20240801101143 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'create tasks table';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
        CREATE TYPE tasks_state AS ENUM(\'IDEA\', \'BACKLOG_ITEM\', \'STARTED\', \'DONE\');
        ');
        $this->addSql('
        CREATE TABLE tasks (
            id UUID PRIMARY KEY,
            category_id UUID NOT NULL,
            title TEXT NOT NULL,
            assignee_id UUID,
            state tasks_state NOT NULL
        );');

        $this->addSql('
        CREATE TABLE tags (
            id UUID PRIMARY KEY,
            name TEXT NOT NULL
        );
        ');
        $this->addSql('
        CREATE TABLE tasks_tags (
            task_id UUID NOT NULL REFERENCES tasks(id),
            tag_id UUID NOT NULL REFERENCES tags(id)
        );
        ');
    }
}
