<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Command\Executor;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\Command\Executor\CreateIdeaExecutor;
use Ramona\Ras2\Task\Command\UpsertIdea;
use Ramona\Ras2\Task\Idea;
use Ramona\Ras2\Task\TaskDescription;
use Ramona\Ras2\Task\TaskId;
use Tests\Ramona\Ras2\Task\Mocks\MockRepository;

final class CreateIdeaExecutorTest extends TestCase
{
    public function testCanCreateIdea(): void
    {
        $repository = new MockRepository();
        $id = TaskId::generate();
        $executor = new CreateIdeaExecutor($repository);
        $executor->execute(new UpsertIdea($id, 'This is a great idea', new ArrayCollection()));

        self::assertEquals([
            new Idea(new TaskDescription($id, 'This is a great idea', new ArrayCollection())),
        ], $repository->tasks());
    }
}
