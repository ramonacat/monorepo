<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * @psalm-suppress UnusedClass
 */
final class Version20240807084237 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Add table for tokens for the users';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
        CREATE TABLE user_tokens(
            id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            token TEXT NOT NULL
        );
        ');
    }
}
