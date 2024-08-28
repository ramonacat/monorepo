<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use DI\Container;
use Laminas\Diactoros\ServerRequest;
use Laminas\Diactoros\Stream;
use League\Route\Http\Exception\BadRequestException;
use League\Route\Http\Exception\NotAcceptableException;
use PHPUnit\Framework\TestCase;
use Psr\Log\NullLogger;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\DefaultCommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\DefaultCommandExecutor;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\DefaultHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ScalarHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultDeserializer;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Mocks\MockCommand;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Mocks\MockCommandExecutor;

final class DefaultCommandExecutorTest extends TestCase
{
    public function testThrowsOnNonJSONRequest(): void
    {
        $request = new ServerRequest();

        $executor = new DefaultCommandExecutor(new DefaultDeserializer(
            new DefaultHydrator(),
            new NullLogger()
        ), new DefaultCommandBus(new Container()));

        $this->expectException(NotAcceptableException::class);
        $executor->execute($request, []);
    }

    public function testThrowsOnUnknownAction(): void
    {
        $request = new ServerRequest(headers: [
            'Content-Type' => 'application/json',
            'X-Action' => 'upsert',
        ]);
        $executor = new DefaultCommandExecutor(new DefaultDeserializer(
            new DefaultHydrator(),
            new NullLogger()
        ), new DefaultCommandBus(new Container()));

        $this->expectException(BadRequestException::class);
        $executor->execute($request, []);
    }

    public function testWillExecuteACommand(): void
    {
        $request = new ServerRequest(
            body: new Stream('php://memory', 'rw'),
            headers: [
                'Content-Type' => 'application/json',
                'X-Action' => 'upsert',
            ]
        );
        $mockCommandExecutor = new MockCommandExecutor();
        $commandBus = new DefaultCommandBus(new Container());
        $commandBus->installExecutor(MockCommand::class, $mockCommandExecutor);
        $hydrator = new DefaultHydrator();
        $hydrator->installValueHydrator(new ScalarHydrator('string'));
        $executor = new DefaultCommandExecutor(new DefaultDeserializer($hydrator, new NullLogger()), $commandBus);

        $request->getBody()
            ->write('{"value":123}');
        $request->getBody()
            ->seek(0);

        $executor->execute($request, [
            'upsert' => MockCommand::class,
        ]);

        self::assertNotNull($mockCommandExecutor->receivedCommand);
    }
}
