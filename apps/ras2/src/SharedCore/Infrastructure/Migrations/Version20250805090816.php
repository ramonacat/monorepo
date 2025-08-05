<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20250805090816 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('DROP TABLE event_attendees');
        $this->addSql('DROP TABLE events');
        $this->addSql('DROP TABLE music_track');
        $this->addSql('DROP TABLE music_album');
        $this->addSql('DROP TABLE music_artist');
        $this->addSql('DROP TABLE music_libraries');
        $this->addSql('DROP TABLE tasks_filters');
        $this->addSql('DROP TABLE tasks_tags');
        $this->addSql('DROP TABLE tasks');
        $this->addSql('DROP TABLE tasks_user_profile');
        $this->addSql('DROP TABLE tags');
    }
}
