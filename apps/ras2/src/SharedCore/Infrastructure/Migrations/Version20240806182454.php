<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * @psalm-suppress UnusedClass
 */
final class Version20240806182454 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Create the users table';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            CREATE TABLE users (
                id uuid PRIMARY KEY,
                name TEXT NOT NULL
            );
        ');
    }
}
