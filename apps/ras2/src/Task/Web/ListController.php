<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Web;

use Laminas\Diactoros\Response;
use Psr\Http\Message\ResponseInterface;
use Ramona\Ras2\Task\Query\AllTasksByCategory;
use Ramona\Ras2\Task\Query\Executor\AllTasksByCategoryExecutor;

final class ListController
{
    private AllTasksByCategoryExecutor $allTasksByCategoryExecutor;

    private \Latte\Engine $latte;

    public function __construct(
        \Latte\Engine $latte,
        AllTasksByCategoryExecutor $allTasksByCategoryExecutor
    ) {
        $this->allTasksByCategoryExecutor = $allTasksByCategoryExecutor;
        $this->latte = $latte;
    }

    public function __invoke(): ResponseInterface
    {
        $response = new Response();
        $tasks = $this->allTasksByCategoryExecutor->execute(new AllTasksByCategory());
        $response->getBody()
            ->write($this ->latte->renderToString('tasks.list.html.latte', [
                'tasks' => $tasks,
            ]));
        return $response;
    }
}
