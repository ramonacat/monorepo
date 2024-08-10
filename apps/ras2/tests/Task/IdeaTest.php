<?php

declare(strict_types=1);

namespace Task;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\Business\BacklogItem;
use Ramona\Ras2\Task\Business\Idea;
use Ramona\Ras2\Task\Business\TaskDescription;
use Ramona\Ras2\Task\Business\TaskId;

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
