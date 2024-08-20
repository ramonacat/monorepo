<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20240820172957 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'add timezone to user profile';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            ALTER TABLE users ADD COLUMN timezone text 
         ');
        $this->addSql('UPDATE users SET timezone=\'Europe/Warsaw\' WHERE timezone IS NULL');
        $this->addSql('
            ALTER TABLE users ALTER COLUMN timezone SET NOT NULL
         ');
    }
}
