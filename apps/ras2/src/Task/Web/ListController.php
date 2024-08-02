<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Web;

use Doctrine\Common\Collections\ArrayCollection;
use Laminas\Diactoros\Response;
use Psr\Http\Message\ResponseInterface;
use Ramona\Ras2\Task\CategoryId;
use Ramona\Ras2\Task\Query\AllTasksByCategory;
use Ramona\Ras2\Task\Query\Executor\AllTasksByCategoryExecutor;
use Ramona\Ras2\Task\Query\TaskSummary;

final class ListController
{
    private AllTasksByCategoryExecutor $allTasksByCategoryExecutor;

    public function __construct(
        AllTasksByCategoryExecutor $allTasksByCategoryExecutor
    ) {
        $this->allTasksByCategoryExecutor = $allTasksByCategoryExecutor;
    }

    public function __invoke(): ResponseInterface
    {
        $rawTasksByCategory = $this
            ->allTasksByCategoryExecutor
            ->execute(new AllTasksByCategory());

        /** @var ArrayCollection<int, CategoryView> $categories */
        $categories = new ArrayCollection();
        foreach ($rawTasksByCategory as $categoryId => $rawTasks) {
            $categories[] = new CategoryView(CategoryId::fromString($categoryId), $rawTasks->map(
                fn (TaskSummary $t) => new TaskCardView($t)
            ));
        }
        $taskListView = new TaskListView($categories);
        $view = new RootView((string) $taskListView);

        $response = new Response();
        $response->getBody()
            ->write((string) $view);
        return $response;
    }
}
