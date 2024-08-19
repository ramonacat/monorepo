<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20240818093638 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'create a table to store systems';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
        CREATE TABLE systems (
            id uuid PRIMARY KEY,
            hostname TEXT,
            operating_system JSONB
        );      
        ');
    }
}
