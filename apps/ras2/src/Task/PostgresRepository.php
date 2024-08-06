<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Doctrine\DBAL\Connection;

final class PostgresRepository implements Repository
{
    public function __construct(
        private Connection $connection
    ) {
    }

    public function save(Task $task): void
    {
        $this->connection->transactional(function () use ($task) {
            $this->connection->executeQuery('
                INSERT INTO tasks(id, title, assignee_id, state) 
                VALUES (:id, :title, :assignee_id, :state) 
                ON CONFLICT (id) DO UPDATE
                    SET title=:title, assignee_id=:assignee_id, state=:state
            ', [
                'id' => (string) $task->id(),
                'title' => $task->title(),
                'assignee_id' => $task->assigneeId(),
                'state' => $this->createStateValue(get_class($task)),
            ]);

            $this->connection->executeQuery('DELETE FROM tasks_tags WHERE task_id=:task_id', [
                'task_id' => $task->id(),
            ]);
            $prepared = $this->connection->prepare(
                'INSERT INTO tasks_tags(task_id, tag_id) VALUES (:task_id, :tag_id)'
            );
            foreach ($task->tags() as $tagId) {
                $prepared->bindValue(':task_id', (string) $task->id());
                $prepared->bindValue(':tag_id', (string) $tagId);
                $prepared->executeStatement();
            }
        });
    }

    public function fetchOrCreateTags(array $tags): array
    {
        $foundTags = $this
            ->connection
            ->executeQuery(
                'SELECT id, name FROM tags WHERE name IN(select value::text from json_array_elements(:tags))',
                [
                    'tags' => \Safe\json_encode($tags),
                ]
            )
            ->fetchAllAssociative();

        $result = [];
        $toCreate = [];

        /** @var array<string, string> $foundMap */
        $foundMap = [];
        foreach ($foundTags as $tag) {
            $foundMap[(string) $tag['name']] = (string) $tag['id'];
        }

        foreach ($tags as $tag) {
            if (isset($foundMap[$tag])) {
                $result[] = TagId::fromString($foundMap[$tag]);
            } else {
                $toCreate[] = $tag;
            }
        }

        $insert = $this->connection->prepare('INSERT INTO tags(id, name) VALUES(:id, :name)');

        foreach ($toCreate as $tagName) {
            $id = TagId::generate();

            $insert->bindValue(':id', (string) $id);
            $insert->bindValue(':name', $tagName);
            $insert->executeStatement();

            $result[] = $id;
        }

        return $result;
    }

    public function transactional(\Closure $action): void
    {
        $this->connection->transactional($action);
    }

    private function createStateValue(string $className): string
    {
        switch ($className) {
            case Idea::class: return 'IDEA';
            case Started::class: return 'STARTED';
            case BacklogItem::class: return 'BACKLOG_ITEM';
            case Done::class: return 'DONE';
            default: throw UnknownTaskType::of($className);
        }
    }
}
