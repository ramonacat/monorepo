<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * @psalm-suppress UnusedClass
 */
final class Version20240807184024 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Add deadline to tasks';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            ALTER TABLE tasks ADD COLUMN deadline timestamptz
        ');
    }
}
