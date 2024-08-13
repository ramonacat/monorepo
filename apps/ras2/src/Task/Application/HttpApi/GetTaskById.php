<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use Laminas\Diactoros\Response;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Application\Query\ById;
use Ramona\Ras2\Task\Business\TaskId;

final readonly class GetTaskById
{
    public function __construct(
        private QueryBus $queryBus,
        private Serializer $serializer
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $taskId = $request->getAttribute('id');

        $task = $this->queryBus->execute(new ById(TaskId::fromString($taskId)));

        $response = new Response(headers: [
            'Content-Type' => 'application/json',
        ]);
        $response->getBody()
            ->write($this->serializer->serialize($task));
        $response->getBody()
            ->seek(0);
        return $response;
    }
}
