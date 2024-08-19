<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20240818182749 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Add the operating_system_type column to systems table';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('CREATE TYPE operating_system_type AS ENUM (\'NIXOS\');');
        $this->addSql('ALTER TABLE systems ADD COLUMN operating_system_type operating_system_type;');
        $this->addSql('UPDATE systems SET operating_system_type = \'NIXOS\';');
        $this->addSql('ALTER TABLE systems ALTER COLUMN operating_system_type SET NOT NULL');
    }
}
