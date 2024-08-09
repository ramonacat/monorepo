<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\HttpApi;

use Laminas\Diactoros\Response;
use League\Route\Http\Exception\NotFoundException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\User\Session;

final class GetUsers
{
    public function __construct(
        private Serializer $serializer
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $queryParams = $request->getQueryParams();
        if (! array_key_exists('action', $queryParams)) {
            throw new NotFoundException();
        }

        if ($queryParams['action'] !== 'session') {
            throw new NotFoundException();
        }

        /** @var Session $session */
        $session = $request->getAttribute(RequireLogin::SESSION_ATTRIBUTE);
        $response = new Response(headers: [
            'Content-Type' => 'application/json',
        ]);

        $response->getBody()
            ->write($this->serializer->serialize($session));

        return $response;
    }
}
