<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application\HttpApi;

use League\Route\Http\Exception\NotFoundException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\User\Application\Query\All;
use Ramona\Ras2\User\Application\Session;

final readonly class GetUsers
{
    public function __construct(
        private JsonResponseFactory $responseFactory,
        private QueryBus $queryBus
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        $queryParams = $request->getQueryParams();

        switch ($queryParams['action'] ?? '') {
            case 'session':
                /** @var Session $session */
                $session = $request->getAttribute(RequireLogin::SESSION_ATTRIBUTE);
                return $this->responseFactory->create($session);
            case '':
                $all = $this->queryBus->execute(new All());
                return $this->responseFactory->create($all);
            default:
                throw new NotFoundException();
        }
    }
}
