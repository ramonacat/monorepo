<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20240906080105 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'add track and disc numbers to music_track';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            ALTER TABLE music_track 
                ADD COLUMN track_number INT NOT NULL,
                ADD COLUMN disc_number INT NOT NULL
        ');
    }
}
