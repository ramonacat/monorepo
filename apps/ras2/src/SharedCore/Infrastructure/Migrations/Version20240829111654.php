<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20240829111654 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Create task_filters table';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            CREATE TABLE tasks_filters (
                id UUID PRIMARY KEY,
                name TEXT NOT NULL,
                assignee_ids JSONB NOT NULL,
                tags_ids JSONB NOT NULL
            );
        ');
    }
}
