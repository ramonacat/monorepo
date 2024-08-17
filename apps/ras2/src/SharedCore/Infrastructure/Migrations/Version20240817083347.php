<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20240817083347 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('ALTER TABLE tasks ALTER COLUMN deadline TYPE datetime_with_timezone USING NULL');
    }
}
