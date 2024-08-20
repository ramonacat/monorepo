<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20240819143747 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Add a table for task user profile';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            CREATE TABLE tasks_user_profile (
                user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
                watched_tags JSONB NOT NULL
            );
        ');
    }
}
