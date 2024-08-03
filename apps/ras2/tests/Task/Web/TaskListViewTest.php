<?php

declare(strict_types=1);

namespace Task\Web;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\Query\TaskSummary;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\Task\Web\TaskCardView;
use Ramona\Ras2\Task\Web\TaskListView;
use Ramona\Ras2\UserId;
use Spatie\Snapshots\MatchesSnapshots;

final class TaskListViewTest extends TestCase
{
    use MatchesSnapshots;

    public function testCanRender(): void
    {
        $taskSummaryA = new TaskSummary(
            TaskId::fromString('abd886fa-2546-4ec2-ab99-a6e8cbb01b63'),
            'this is a title',
            UserId::fromString('7e78fb68-bbdc-43e9-9bbf-797dc64c69e1'),
            new ArrayCollection(['tag1', 'tag2']),
            'DOING'
        );
        $taskSummaryB = new TaskSummary(
            TaskId::fromString('c2173f52-bc41-40b0-a159-d648037ecf0c'),
            'this is an title',
            UserId::fromString('2f152787-142c-41ae-a5c9-253b1f39d827'),
            new ArrayCollection(['tag3', 'tag2']),
            'DONE'
        );
        $tasks = new ArrayCollection([$taskSummaryA, $taskSummaryB]);
        $tasks = $tasks->map(fn (TaskSummary $t) => new TaskCardView($t));
        $taskList = new TaskListView($tasks);

        $this->assertMatchesHtmlSnapshot((string) $taskList);
    }
}
