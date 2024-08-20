<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueType;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Business\BacklogItem;
use Ramona\Ras2\Task\Business\Done;
use Ramona\Ras2\Task\Business\Idea;
use Ramona\Ras2\Task\Business\Started;
use Ramona\Ras2\Task\Business\TagId;
use Ramona\Ras2\Task\Business\Task;
use Ramona\Ras2\Task\Business\TaskDescription;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Business\TimeRecord;
use Ramona\Ras2\User\Business\UserId;
use Safe\DateTimeImmutable;

final class PostgresRepository implements Repository
{
    public function __construct(
        private Connection $connection,
        private Serializer $serializer,
        private Deserializer $deserializer
    ) {
    }

    public function save(Task $task): void
    {
        $this->connection->transactional(function () use ($task) {
            $this->connection->executeQuery('
                INSERT INTO tasks(id, title, assignee_id, state, deadline, time_records) 
                VALUES (:id, :title, :assignee_id, :state, :deadline, :time_records) 
                ON CONFLICT (id) DO UPDATE
                    SET 
                        title=:title, 
                        assignee_id=:assignee_id, 
                        state=:state, 
                        deadline=:deadline, 
                        time_records=:time_records
            ', [
                'id' => (string) $task->id(),
                'title' => $task->title(),
                'assignee_id' => $task->assigneeId(),
                'state' => $this->createStateValue(get_class($task)),
                'deadline' => $task->deadline()?->format(DateTimeImmutable::RFC3339),
                'time_records' => $this->serializer->serialize($task->timeRecords()),
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

    public function fetchOrCreateTags(ArrayCollection $tags): ArrayCollection
    {
        $foundTags = $this
            ->connection
            ->executeQuery(
                'SELECT id, name FROM tags WHERE name IN(select value::text from json_array_elements(:tags))',
                [
                    'tags' => \Safe\json_encode($tags->toArray()),
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

        return new ArrayCollection($result);
    }

    public function transactional(\Closure $action): void
    {
        $this->connection->transactional($action);
    }

    public function getById(TaskId $taskId): Task
    {
        /** @var false|array{id: string, title: string, assignee_id: ?string, state: string, deadline: ?string, time_records: string, tags:string} $raw */
        $raw = $this->connection->executeQuery(
            '
                SELECT 
                    id, 
                    title, 
                    assignee_id, 
                    state, 
                    deadline, 
                    time_records, 
                    (
                        SELECT 
                            json_agg(tt.tag_id) 
                        FROM tasks_tags tt 
                        WHERE tt.task_id=t.id
                    ) AS tags
                FROM tasks t
                WHERE id=:id
                ',
            [
                'id' => (string) $taskId,
            ]
        )->fetchAssociative();

        if ($raw === false) {
            throw NotFound::forId($taskId);
        }
        return $this->hydrateTask($raw);

    }

    public function findStartedTasks(UserId $userId): ArrayCollection
    {
        /** @var array<array{id: string, title: string, assignee_id: ?string, state: string, deadline: ?string, time_records: string, tags:string}> $results */
        $results = $this->connection->executeQuery('SELECT 
                    id, 
                    title, 
                    assignee_id, 
                    state, 
                    deadline, 
                    time_records, 
                    (
                        SELECT 
                            json_agg(tt.tag_id) 
                        FROM tasks_tags tt 
                        WHERE tt.task_id=t.id
                    ) AS tags
                FROM tasks t
                WHERE 
                    t.assignee_id=:assignee_id
                    AND t.state = \'STARTED\'
            ', [
            'assignee_id' => $userId,
        ])->fetchAllAssociative();

        $result = new ArrayCollection(array_map($this->hydrateTask(...), $results));
        /** @var ArrayCollection<int, Started> $result */
        return $result;
    }

    /**
     * @param array{id: string, title: string, assignee_id: ?string, state: string, deadline: ?string, time_records: string, tags:string} $raw
     */
    public function hydrateTask(array $raw): Task
    {
        /** @var array<int, string> $rawTags */
        $rawTags = \Safe\json_decode($raw['tags']);
        $tags = array_map(fn (string $raw) => TagId::fromString($raw), $rawTags);

        $taskId = TaskId::fromString($raw['id']);
        $taskDescription = new TaskDescription($taskId, $raw['title'], new ArrayCollection($tags));

        $assigneeId = $raw['assignee_id'] === null ? null : UserId::fromString($raw['assignee_id']);
        /** @var ArrayCollection<int, TimeRecord> $timeRecords */
        $timeRecords = $this->deserializer->deserialize(
            ArrayCollection::class,
            $raw['time_records'],
            [new KeyType('integer'), new ValueType(TimeRecord::class)]
        );

        $deadline = $raw['deadline'] === null
            ? null
            : \Safe\DateTimeImmutable::createFromFormat('Y-m-d H:i:s P', $raw['deadline']);

        return match ($raw['state']) {
            'IDEA' => new Idea($taskDescription),
            'BACKLOG_ITEM' => new BacklogItem($taskDescription, $assigneeId, $deadline, $timeRecords),
            'STARTED' => new Started($taskDescription, $assigneeId ?? throw MissingAssignee::for(
                $taskId
            ), $deadline, $timeRecords),
            'DONE' => new Done($taskDescription, $assigneeId ?? throw MissingAssignee::for($taskId), $timeRecords),
            default => throw UnknownTaskType::of($raw['state'])
        };
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
