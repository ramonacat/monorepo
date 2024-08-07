<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Laminas\Diactoros\Response;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Bus;
use Ramona\Ras2\User\Query\FindByToken;
use Ramona\Ras2\User\Token;
use Ramona\Ras2\User\UserNotFound;

final class RequireLogin implements MiddlewareInterface
{
    public const SESSION_ATTRIBUTE = 'session';

    public function __construct(
        private readonly Bus $queryBus
    ) {
    }

    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        if ($request->getUri()->getPath() === '/users' && $request->getHeaderLine('X-Action') === 'login') {
            return $handler->handle($request);
        }

        $token = $request->getHeaderLine('X-User-Token');

        if ($token === '') {
            return new Response(status: 403);
        }

        try {
            $user = $this->queryBus->execute(new FindByToken(Token::fromString($token)));
        } catch (UserNotFound) {
            return new Response(status: 403);
        }
        $request = $request->withAttribute(self::SESSION_ATTRIBUTE, $user);

        return $handler->handle($request);
    }
}
