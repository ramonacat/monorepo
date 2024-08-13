<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20240813155406 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Add a table for stored credentials';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            CREATE TABLE credentials (
                id UUID,
                name TEXT,
                owner UUID REFERENCES users(id) ON DELETE CASCADE,
                value TEXT
            );        
        ');
    }
}
