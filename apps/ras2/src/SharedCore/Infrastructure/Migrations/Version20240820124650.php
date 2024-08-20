<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20240820124650 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'cleanup duplicate tags and create a UNIQUE constraint';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('
            CREATE TEMPORARY TABLE temp_tags AS 
                SELECT 
                    *, row_number() over (PARTITION BY t.name) as rn
                FROM tags t
        ');

        $this->addSql('
            CREATE TEMPORARY TABLE refs
            AS WITH grouped_tags AS (
                SELECT
                    ARRAY_AGG(t.id) AS groups
                FROM tags t
                GROUP BY t.name
            ), tags_to_update AS (
                SELECT
                    groups[1] as "first",
                    groups as "all"
                FROM grouped_tags
            ), references_to_update AS
                (SELECT tt.task_id,
                        tt.tag_id,
                        ttu."first"
                 FROM tasks_tags tt
                          INNER JOIN tags_to_update ttu ON ttu."all" @> ARRAY [tt.tag_id])
            SELECT * FROM references_to_update;
        ');
        $this->addSql('
            UPDATE tasks_tags tt
                SET tag_id = rtu.first
            FROM refs rtu
            WHERE rtu.tag_id = tt.tag_id
              AND rtu.task_id = tt.task_id
        ');

        $this->addSql('
            DELETE FROM tags WHERE id NOT IN (SELECT "first" FROM refs)
        ');
    }
}
