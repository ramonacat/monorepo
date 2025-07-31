<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20250731162609 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'add latest ping date to the systems table';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('ALTER TABLE systems ADD COLUMN latest_ping datetime_with_timezone');
    }
}
