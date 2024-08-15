<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application\HttpApi;

use League\Route\Http\Exception\NotFoundException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\User\Application\Session;

final readonly class GetUsers
{
    public function __construct(
        private JsonResponseFactory $responseFactory
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $queryParams = $request->getQueryParams();

        if (($queryParams['action'] ?? '') !== 'session') {
            throw new NotFoundException();
        }

        /** @var Session $session */
        $session = $request->getAttribute(RequireLogin::SESSION_ATTRIBUTE);
        return $this->responseFactory->create($session);
    }
}
