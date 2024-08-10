<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * @psalm-suppress UnusedClass
 */
final class Version20240810035846 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Add a field for time records to task table';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            ALTER TABLE tasks ADD COLUMN time_records JSONB NOT NULL DEFAULT \'[]\'::jsonb
        ');
    }
}
