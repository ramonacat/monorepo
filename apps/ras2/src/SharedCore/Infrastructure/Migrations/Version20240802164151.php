<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * @psalm-suppress UnusedClass
 */
final class Version20240802164151 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Remove the concept of categories';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('ALTER TABLE tasks DROP COLUMN category_id');
    }
}
