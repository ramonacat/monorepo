<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Web;

use Laminas\Diactoros\Response;
use Psr\Http\Message\ResponseInterface;
use Ramona\Ras2\Task\Query\AllTasks;
use Ramona\Ras2\Task\Query\Executor\AllTasksExecutor;
use Ramona\Ras2\Task\Query\TaskSummary;

final class ListController
{
    private AllTasksExecutor $allTasksExecutor;

    public function __construct(
        AllTasksExecutor $allTasksExecutor
    ) {
        $this->allTasksExecutor = $allTasksExecutor;
    }

    public function __invoke(): ResponseInterface
    {
        $rawTasks = $this
            ->allTasksExecutor
            ->execute(new AllTasks());

        $tasks = $rawTasks->map(fn (TaskSummary $t) => new TaskCardView($t));
        $taskListView = new TaskListView($tasks);
        $view = new RootView((string) $taskListView);

        $response = new Response();
        $response->getBody()
            ->write((string) $view);
        return $response;
    }
}
