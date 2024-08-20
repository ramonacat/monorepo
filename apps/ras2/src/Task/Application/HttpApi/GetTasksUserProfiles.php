<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use Laminas\Diactoros\Response;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Application\Query\UserProfileByUserId;
use Ramona\Ras2\User\Application\Session;

final class GetTasksUserProfiles
{
    public function __construct(
        private QueryBus $queryBus,
        private Serializer $serializer
    ) {

    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        /** @var Session $session */
        $session = $request->getAttribute(RequireLogin::SESSION_ATTRIBUTE);
        $query = new UserProfileByUserId($session->userId);

        $result = $this->queryBus->execute($query);

        $response = new Response();
        $response->getBody()
            ->write($this->serializer->serialize($result));
        return $response;
    }
}
