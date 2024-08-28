<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition;

use Laminas\Diactoros\Response\EmptyResponse;
use Laminas\Diactoros\ServerRequest;
use League\Route\Http\Exception\NotAcceptableException;
use League\Route\Http\Exception\NotFoundException;
use League\Route\RouteCollectionInterface;
use PHPUnit\Framework\TestCase;
use Psr\Log\NullLogger;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIRouter;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\CommandCallbackDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\CommandDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\QueryCallbackDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\QueryDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\DefaultJsonResponseFactory;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Tests\Ramona\Ras2\ClassFinderFactory;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Mocks\MockCommand;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Mocks\MockQuery;

final class APIRouterTest extends TestCase
{
    public function testCanRouteACommand(): void
    {
        $deserializer = $this->createMock(Deserializer::class);
        $deserializer
            ->expects(self::once())
            ->method('deserialize')
            ->willReturnCallback(function () {
                return new MockCommand();
            });
        $apiRouter = new APIRouter(
            $this->createMock(CommandBus::class),
            $this->createMock(QueryBus::class),
            $deserializer,
            $this->createMock(JsonResponseFactory::class),
            $this->createMock(Hydrator::class),
            new NullLogger()
        );

        $definition = new APIDefinition(ClassFinderFactory::create());
        $definition->installCommand(new CommandDefinition('test1', 'test1', MockCommand::class));
        $definition->installCommand(new CommandDefinition('test', 'test1', MockCommand::class));
        $definition->installCommand(new CommandDefinition('test', 'test2', MockCommand::class));
        $router = $this->createMock(RouteCollectionInterface::class);
        $router
            ->expects(self::exactly(2))
            ->method('map')
            ->willReturnCallback(function (string $method, string $path, callable $callback) {
                self::assertEquals('POST', $method);

                if ($path === 'test') {
                    $response = ($callback)(new ServerRequest(headers: [
                        'X-Action' => 'test2',
                        'Content-Type' => 'application/json',
                    ]));
                    self::assertInstanceOf(EmptyResponse::class, $response);
                }

                return new \League\Route\Route($method, $path, $callback);
            });
        $apiRouter->register($definition, $router);
    }

    public function testCanRouteACommandCallback(): void
    {
        $serializer = $this->createMock(Serializer::class);
        $serializer->method('serialize')
            ->willReturn('"test"');
        $apiRouter = new APIRouter(
            $this->createMock(CommandBus::class),
            $this->createMock(QueryBus::class),
            $this->createMock(Deserializer::class),
            new DefaultJsonResponseFactory($serializer),
            $this->createMock(Hydrator::class),
            new NullLogger()
        );

        $callbackCalled = false;

        $definition = new APIDefinition(ClassFinderFactory::create());
        $definition->installCommandCallback(
            new CommandCallbackDefinition('test1', 'test1', function () {}, 'string', 'string')
        );
        $definition->installCommandCallback(
            new CommandCallbackDefinition('test2', 'test2', function () {}, 'string', 'string')
        );
        $definition->installCommandCallback(new CommandCallbackDefinition('test2', 'test3', function () use (
            &$callbackCalled
        ) {
            $callbackCalled = true;
            return 'test';
        }, 'string', 'string'));
        $router = $this->createMock(RouteCollectionInterface::class);
        $router
            ->expects(self::exactly(2))
            ->method('map')
            ->willReturnCallback(function (string $method, string $path, callable $callback) {
                self::assertEquals('POST', $method);

                if ($path === 'test2') {
                    $response = ($callback)(new ServerRequest(headers: [
                        'X-Action' => 'test3',
                        'Content-Type' => 'application/json',
                    ]));
                    $response->getBody()
                        ->seek(0);
                    $jsonResponse = $response->getBody()
                        ->getContents();

                    self::assertEquals('"test"', $jsonResponse);
                }

                return new \League\Route\Route($method, $path, $callback);
            });
        $apiRouter->register($definition, $router);

        self::assertEquals($callbackCalled, true);
    }

    public function testThrowsOnNonJsonRequest(): void
    {
        $deserializer = $this->createMock(Deserializer::class);
        $apiRouter = new APIRouter(
            $this->createMock(CommandBus::class),
            $this->createMock(QueryBus::class),
            $deserializer,
            $this->createMock(JsonResponseFactory::class),
            $this->createMock(Hydrator::class),
            new NullLogger()
        );

        $definition = new APIDefinition(ClassFinderFactory::create());
        $definition->installCommand(new CommandDefinition('test1', 'test1', MockCommand::class));
        $definition->installCommand(new CommandDefinition('test', 'test1', MockCommand::class));
        $definition->installCommand(new CommandDefinition('test', 'test2', MockCommand::class));
        $router = $this->createMock(RouteCollectionInterface::class);
        $router
            ->expects(self::exactly(2))
            ->method('map')
            ->willReturnCallback(function (string $method, string $path, callable $callback) {
                self::assertEquals('POST', $method);

                if ($path === 'test') {
                    ($callback)(new ServerRequest(headers: [
                        'X-Action' => 'test2',
                    ]));
                }

                return new \League\Route\Route($method, $path, $callback);
            });

        $this->expectException(NotAcceptableException::class);
        $apiRouter->register($definition, $router);
    }

    public function testThrowsOnUnknownAction(): void
    {
        $deserializer = $this->createMock(Deserializer::class);
        $apiRouter = new APIRouter(
            $this->createMock(CommandBus::class),
            $this->createMock(QueryBus::class),
            $deserializer,
            $this->createMock(JsonResponseFactory::class),
            $this->createMock(Hydrator::class),
            new NullLogger()
        );

        $definition = new APIDefinition(ClassFinderFactory::create());
        $definition->installCommand(new CommandDefinition('test1', 'test1', MockCommand::class));
        $definition->installCommand(new CommandDefinition('test', 'test1', MockCommand::class));
        $definition->installCommand(new CommandDefinition('test', 'test2', MockCommand::class));
        $router = $this->createMock(RouteCollectionInterface::class);
        $router
            ->expects(self::exactly(2))
            ->method('map')
            ->willReturnCallback(function (string $method, string $path, callable $callback) {
                self::assertEquals('POST', $method);

                if ($path === 'test') {
                    ($callback)(new ServerRequest(headers: [
                        'X-Action' => 'test5',
                        'Content-Type' => 'application/json',
                    ]));
                }

                return new \League\Route\Route($method, $path, $callback);
            });

        $this->expectException(NotFoundException::class);
        $apiRouter->register($definition, $router);
    }

    public function testCanRouteAQuery(): void
    {
        $hydrator = $this->createMock(Hydrator::class);
        $hydrator->method('hydrate')
            ->willReturn(new MockQuery());

        $serializer = $this->createMock(Serializer::class);
        $serializer->method('serialize')
            ->willReturn('this is test');
        $apiRouter = new APIRouter(
            $this->createMock(CommandBus::class),
            $this->createMock(QueryBus::class),
            $this->createMock(Deserializer::class),
            new DefaultJsonResponseFactory($serializer),
            $hydrator,
            new NullLogger()
        );

        $definition = new APIDefinition(ClassFinderFactory::create());
        $definition->installQuery(new QueryDefinition('test1', 'test1', MockQuery::class));
        $definition->installQuery(new QueryDefinition('test2', 'test2', MockQuery::class));
        $definition->installQuery(new QueryDefinition('test2', 'test3', MockQuery::class));
        $router = $this->createMock(RouteCollectionInterface::class);
        $router
            ->expects(self::exactly(2))
            ->method('map')
            ->willReturnCallback(function (string $method, string $path, callable $callback) {
                self::assertEquals('GET', $method);

                if ($path === 'test2') {
                    $response = ($callback)(new ServerRequest(headers: [
                        'Content-Type' => 'application/json',
                    ], queryParams: [
                        'action' => 'test3',
                    ]));
                    $response->getBody()
                        ->seek(0);
                    self::assertEquals('this is test', $response->getBody()->getContents());
                }

                return new \League\Route\Route($method, $path, $callback);
            });
        $apiRouter->register($definition, $router);
    }

    public function testCanRouteAQueryCallaback(): void
    {
        $hydrator = $this->createMock(Hydrator::class);
        $hydrator->method('hydrate')
            ->willReturn(new MockQuery());

        $serializer = $this->createMock(Serializer::class);
        $serializer->method('serialize')
            ->willReturnCallback('json_encode');
        $apiRouter = new APIRouter(
            $this->createMock(CommandBus::class),
            $this->createMock(QueryBus::class),
            $this->createMock(Deserializer::class),
            new DefaultJsonResponseFactory($serializer),
            $hydrator,
            new NullLogger()
        );

        $definition = new APIDefinition(ClassFinderFactory::create());
        $definition->installQueryCallback(
            new QueryCallbackDefinition('test1', 'test1', function () {}, 'string', 'string')
        );
        $definition->installQueryCallback(
            new QueryCallbackDefinition('test2', 'test2', function () {}, 'string', 'string')
        );
        $definition->installQueryCallback(new QueryCallbackDefinition('test2', 'test3', function () {
            return 'this is test';
        }, 'string', 'string'));
        $router = $this->createMock(RouteCollectionInterface::class);
        $router
            ->expects(self::exactly(2))
            ->method('map')
            ->willReturnCallback(function (string $method, string $path, callable $callback) {
                self::assertEquals('GET', $method);

                if ($path === 'test2') {
                    $response = ($callback)(new ServerRequest(headers: [
                        'Content-Type' => 'application/json',
                    ], queryParams: [
                        'action' => 'test3',
                    ]));
                    $response->getBody()
                        ->seek(0);
                    self::assertEquals('application/json', $response->getHeaderLine('Content-Type'));
                    self::assertEquals('"this is test"', $response->getBody()->getContents());
                }

                return new \League\Route\Route($method, $path, $callback);
            });
        $apiRouter->register($definition, $router);
    }

    public function testThrowsOnNotFoundQuery(): void
    {
        $hydrator = $this->createMock(Hydrator::class);
        $hydrator->method('hydrate')
            ->willReturn(new MockQuery());

        $serializer = $this->createMock(Serializer::class);
        $serializer->method('serialize')
            ->willReturn('this is test');
        $apiRouter = new APIRouter(
            $this->createMock(CommandBus::class),
            $this->createMock(QueryBus::class),
            $this->createMock(Deserializer::class),
            new DefaultJsonResponseFactory($serializer),
            $hydrator,
            new NullLogger()
        );

        $definition = new APIDefinition(ClassFinderFactory::create());
        $definition->installQuery(new QueryDefinition('test1', 'test1', MockQuery::class));
        $definition->installQuery(new QueryDefinition('test2', 'test2', MockQuery::class));
        $definition->installQuery(new QueryDefinition('test2', 'test3', MockQuery::class));
        $router = $this->createMock(RouteCollectionInterface::class);
        $router
            ->expects(self::exactly(2))
            ->method('map')
            ->willReturnCallback(function (string $method, string $path, callable $callback) {
                self::assertEquals('GET', $method);

                if ($path === 'test2') {
                    $response = ($callback)(new ServerRequest(headers: [
                        'Content-Type' => 'application/json',
                    ], queryParams: [
                        'action' => 'test7',
                    ]));
                }

                return new \League\Route\Route($method, $path, $callback);
            });

        $this->expectException(NotFoundException::class);
        $apiRouter->register($definition, $router);
    }
}
