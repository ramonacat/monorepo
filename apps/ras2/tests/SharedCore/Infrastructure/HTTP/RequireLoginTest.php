<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Laminas\Diactoros\ServerRequest;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Bus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\User\Query\FindByToken;
use Ramona\Ras2\User\Session;
use Ramona\Ras2\User\UserId;

final class RequireLoginTest extends TestCase
{
    public function testWillAllowLoginAccess(): void
    {
        $request = new ServerRequest(uri: 'http://localhost:8080/users', headers: [
            'X-Action' => 'login',
        ]);
        $requireLogin = new RequireLogin(new Bus());

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
        $bus = new Bus();
        $userId = UserId::generate();
        $username = 'ramona';
        $bus->installExecutor(FindByToken::class, new FindByTokenExecutorMock($userId, $username));
        $requireLogin = new RequireLogin($bus);

        $requestHandler = new MockRequestHandler();
        $requireLogin->process($request, $requestHandler);

        self::assertEquals(new Session($userId, $username), $requestHandler->request?->getAttribute('session'));
    }

    public function testWillFailOnMissingToken(): void
    {
        $request = new ServerRequest(uri: 'http://localhost:8080/users');

        $requireLogin = new RequireLogin(new Bus());

        $response = $requireLogin->process($request, new MockRequestHandler());
        $response->getBody()
            ->seek(0);

        self::assertEquals(403, $response->getStatusCode());
        self::assertEquals('', $response->getBody()->getContents());
    }
}
