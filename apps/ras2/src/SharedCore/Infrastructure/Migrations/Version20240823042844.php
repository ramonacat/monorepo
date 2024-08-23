<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20240823042844 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'add the is_system column to the users table';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            ALTER TABLE users ADD COLUMN is_system BIT NOT NULL DEFAULT 0::BIT
        ');
    }
}
