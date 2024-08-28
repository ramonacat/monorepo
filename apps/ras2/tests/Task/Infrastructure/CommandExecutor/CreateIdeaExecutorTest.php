<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;
use Ramona\Ras2\Task\Business\Idea;
use Ramona\Ras2\Task\Business\TaskDescription;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\UpsertIdeaExecutor;
use Tests\Ramona\Ras2\Task\Mocks\MockRepository;

final class CreateIdeaExecutorTest extends TestCase
{
    public function testCanCreateIdea(): void
    {
        $repository = new MockRepository();
        $id = TaskId::generate();
        $executor = new UpsertIdeaExecutor($repository);
        $executor->execute(new UpsertIdea($id, 'This is a great idea', new ArrayCollection()));

        self::assertEquals([
            new Idea(new TaskDescription($id, 'This is a great idea', new ArrayCollection())),
        ], $repository->tasks());
    }
}
