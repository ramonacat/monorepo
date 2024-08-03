<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Web;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\Query\TaskSummary;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\Task\Web\TaskCardView;
use Ramona\Ras2\UserId;
use Spatie\Snapshots\MatchesSnapshots;

final class TaskCardViewTest extends TestCase
{
    use MatchesSnapshots;

    public function testCanRenderASimpleCard(): void
    {
        $summary = new TaskSummary(
            TaskId::fromString('fd3d88d3-a1e2-4d52-9946-65f58089ed9a'),
            'this is a title',
            UserId::fromString('22283ca9-1c8f-47ec-b738-77ce22539609'),
            new ArrayCollection(['tag1', 'tag2', 'tag3']),
            'DOING'
        );
        $view = new TaskCardView($summary);
        $this->assertMatchesHtmlSnapshot((string) $view);
    }
}
