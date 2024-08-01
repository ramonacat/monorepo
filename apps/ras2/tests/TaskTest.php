<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task;

final class TaskTest extends TestCase
{
    public function testHasADescription(): void
    {
        $task = new Task('do a thing!');

        self::assertSame('do a thing!', $task->description());
    }
}
