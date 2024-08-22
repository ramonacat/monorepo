<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition;

use Laminas\Diactoros\Response\EmptyResponse;
use League\Route\Http\Exception\NotFoundException;
use League\Route\RouteCollectionInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\AssertRequest;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;

final readonly class APIRouter
{
    public function __construct(
        private CommandBus $commandBus,
        private QueryBus $queryBus,
        private Deserializer $deserializer,
        private JsonResponseFactory $jsonResponseFactory,
        private Hydrator $hydrator
    ) {
    }

    public function register(APIDefinition $definition, RouteCollectionInterface $router): void
    {
        $commands = $definition->commands();
        $commandCallbacks = $definition->commandCallbacks();
        $paths = [...array_keys($commands), ...array_keys($commandCallbacks)];

        foreach ($paths as $path) {
            $router->map('POST', $path, function (ServerRequestInterface $request) use (
                $commands,
                $path,
                $commandCallbacks
            ) {
                AssertRequest::isJson($request);
                $action = $request->getHeaderLine('X-Action');

                if (! isset($commands[$path][$action]) && ! isset($commandCallbacks[$path][$action])) {
                    throw new NotFoundException();
                }

                if (isset($commands[$path][$action])) {
                    $command = $commands[$path][$action];
                    $this->commandBus->execute(
                        $this->deserializer->deserialize($command, $request->getBody()->getContents())
                    );

                    return new EmptyResponse();
                }
                $result = ($commandCallbacks[$path][$action])($request);

                if ($result === null) {
                    return new EmptyResponse();
                }
                return $this->jsonResponseFactory->create($result);

            });
        }

        $queries = $definition->queries();
        $queryCallbacks = $definition->queryCallbacks();

        $pathsFromQueries = array_keys($queries);
        $pathsFromQueryCallbacks = array_keys($queryCallbacks);

        $paths = [...$pathsFromQueries, ...$pathsFromQueryCallbacks];

        foreach ($paths as $path) {
            $router->map('GET', $path, function (ServerRequestInterface $request) use (
                $path,
                $queryCallbacks,
                $queries
            ) {
                $queryString = $request->getQueryParams();
                $action = $queryString['action'] ?? '';

                if (! isset($queries[$path][$action]) && ! isset($queryCallbacks[$path][$action])) {
                    throw new NotFoundException();
                }

                if (isset($queries[$path][$action])) {
                    $queryType = $queries[$path][$action];

                    $query = $this->hydrator->hydrate($queryType, $queryString);
                    $result = $this->queryBus->execute($query);
                } else {
                    $result = ($queryCallbacks[$path][$action])($request);
                }

                return $this->jsonResponseFactory->create($result);
            });
        }
    }
}
