<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20240905094850 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'create the music tables';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            CREATE TABLE music_artist(
                id UUID PRIMARY KEY,
                name TEXT NOT NULL 
            );
        ');
        $this->addSql('
            CREATE TABLE music_album(
                id UUID PRIMARY KEY,
                library_id UUID REFERENCES music_libraries(id) NOT NULL,
                artist_id UUID REFERENCES music_artist(id) NOT NULL,
                title TEXT NOT NULL
            );
        ');
        $this->addSql('
            CREATE TABLE music_track(
                id UUID PRIMARY KEY,
                album_id UUID REFERENCES music_album(id) NOT NULL,
                title TEXT NOT NULL,
                path TEXT NOT NULL
            )
        ');
    }
}
