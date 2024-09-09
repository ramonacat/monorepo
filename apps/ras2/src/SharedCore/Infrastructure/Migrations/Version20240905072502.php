<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20240905072502 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'create the libraries table';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            CREATE TABLE music_libraries (
                id UUID PRIMARY KEY,
                path TEXT NOT NULL
            );
        ');
    }
}
