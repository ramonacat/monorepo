<?php

declare(strict_types=1);

namespace Task;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\BacklogItem;
use Ramona\Ras2\Task\Idea;
use Ramona\Ras2\Task\TaskDescription;
use Ramona\Ras2\Task\TaskId;

final class IdeaTest extends TestCase
{
    public function testCanBeMovedToBacklog(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection([]));
        $idea = new Idea($description);

        $result = $idea->toBacklog(null);

        self::assertInstanceOf(BacklogItem::class, $result);
        self::assertEquals($description, $result->description());
    }
}
