<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;
use Ramona\Ras2\Task\Application\Query\ById;
use Ramona\Ras2\Task\Business\TaskId;

final readonly class GetTaskById
{
    public function __construct(
        private QueryBus $queryBus,
        private JsonResponseFactory $responseFactory
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $taskId = $request->getAttribute('id');

        $task = $this->queryBus->execute(new ById(TaskId::fromString($taskId)));

        return $this->responseFactory->create($task);
    }
}
