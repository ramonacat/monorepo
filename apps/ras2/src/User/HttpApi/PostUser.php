<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\HttpApi;

use Laminas\Diactoros\Response;
use Laminas\Diactoros\Response\EmptyResponse;
use League\Route\Http\Exception\BadRequestException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Bus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\AssertRequest;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\User\Command\Login;
use Ramona\Ras2\User\Command\LoginRequest;
use Ramona\Ras2\User\Command\LoginResponse;
use Ramona\Ras2\User\Command\UpsertUser;
use Ramona\Ras2\User\Token;

final class PostUser
{
    public function __construct(
        private Bus $commandBus,
        private Serializer $serializer,
        private Deserializer $deserializer
    ) {
    }

    public function __invoke(ServerRequestInterface $serverRequest): ResponseInterface
    {
        AssertRequest::isJson($serverRequest);

        $requestedAction = $serverRequest->getHeaderLine('X-Action');

        if ($requestedAction === 'upsert') {
            return $this->upsert($serverRequest);
        } elseif ($requestedAction === 'login') {
            return $this->login($serverRequest);
        }

        throw new BadRequestException();
    }

    public function upsert(ServerRequestInterface $serverRequest): EmptyResponse
    {
        $command = $this->deserializer->deserialize(UpsertUser::class, $serverRequest->getBody() ->getContents());

        $this->commandBus->execute($command);

        return new EmptyResponse();
    }

    private function login(ServerRequestInterface $request): ResponseInterface
    {
        $request = $this->deserializer->deserialize(LoginRequest::class, $request->getBody()->getContents());

        $token = Token::generate();

        $this->commandBus->execute(new Login($token, $request->username));

        $response = new Response(
            headers: [
                'Content-Type' => 'application/json',
            ]
        );
        $response->getBody()
            ->write($this ->serializer ->serialize(new LoginResponse($token)));
        return $response;
    }
}
