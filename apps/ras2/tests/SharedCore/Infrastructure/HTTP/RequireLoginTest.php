<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Laminas\Diactoros\ServerRequest;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\User\Application\Query\ByToken;
use Ramona\Ras2\User\Application\Session;
use Ramona\Ras2\User\Business\UserId;
use Ramona\Ras2\User\Infrastructure\UserNotFound;

final class RequireLoginTest extends TestCase
{
    public function testWillAllowLoginAccess(): void
    {
        $request = new ServerRequest(uri: 'http://localhost:8080/users', headers: [
            'X-Action' => 'login',
        ]);
        $requireLogin = new RequireLogin(new QueryBus());

        $response = $requireLogin->process($request, new MockRequestHandler());
        $response->getBody()
            ->seek(0);

        self::assertEquals('ok', $response->getBody()->getContents());
    }

    public function testWillSetTheAttribute(): void
    {
        $request = new ServerRequest(uri: 'http://localhost:8080/users', headers: [
            'X-Action' => 'upsert',
            'X-User-Token' => 'bped6gRpDIP0S+xQMDKkdsfj2qhSUVr/obnOspHdz2rfoR99vCQee3BEx+9GaX6yRIOTMp6lxADW/YRoIrxImA==',
        ]);
        $bus = new QueryBus();
        $userId = UserId::generate();
        $username = 'ramona';
        $bus->installExecutor(
            ByToken::class,
            new FindByTokenExecutorMock(fn () => new Session(
                $userId,
                $username,
                new \DateTimeZone('Europe/Berlin')
            ))
        );
        $requireLogin = new RequireLogin($bus);

        $requestHandler = new MockRequestHandler();
        $requireLogin->process($request, $requestHandler);

        self::assertEquals(new Session(
            $userId,
            $username,
            new \DateTimeZone('Europe/Berlin')
        ), $requestHandler->request?->getAttribute('session'));
    }

    public function testWillFailOnMissingToken(): void
    {
        $request = new ServerRequest(uri: 'http://localhost:8080/users');

        $requireLogin = new RequireLogin(new QueryBus());

        $response = $requireLogin->process($request, new MockRequestHandler());
        $response->getBody()
            ->seek(0);

        self::assertEquals(403, $response->getStatusCode());
        self::assertEquals('', $response->getBody()->getContents());
    }

    public function testWillFailOnTokenNotFound(): void
    {
        $request = new ServerRequest(uri: 'http://localhost:8080/users', headers: [
            'X-Action' => 'upsert',
            'X-User-Token' => 'bped6gRpDIP0S+xQMDKkdsfj2qhSUVr/obnOspHdz2rfoR99vCQee3BEx+9GaX6yRIOTMp6lxADW/YRoIrxImA==',
        ]);
        $bus = new QueryBus();
        $bus->installExecutor(
            ByToken::class,
            new FindByTokenExecutorMock(fn () => throw UserNotFound::withToken())
        );
        $requireLogin = new RequireLogin($bus);

        $response = $requireLogin->process($request, new MockRequestHandler());
        $response->getBody()
            ->seek(0);

        self::assertEquals('', $response->getBody()->getContents());
        self::assertEquals(403, $response->getStatusCode());
    }
}
