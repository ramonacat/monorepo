<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\HttpApi;

use Laminas\Diactoros\Response;
use Laminas\Diactoros\Response\EmptyResponse;
use League\Route\Http\Exception\BadRequestException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\CQRS\Command\Bus;
use Ramona\Ras2\HTTP\AssertRequest;
use Ramona\Ras2\Serialization\SerializerInterface;
use Ramona\Ras2\User\Command\Login;
use Ramona\Ras2\User\Command\LoginRequest;
use Ramona\Ras2\User\Command\LoginResponse;
use Ramona\Ras2\User\Command\UpsertUser;
use Ramona\Ras2\User\Token;

final class PostUser
{
    public function __construct(
        private Bus $commandBus,
        private SerializerInterface $serializer
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
        $command = $this->serializer->deserialize($serverRequest->getBody() ->getContents(), UpsertUser::class);

        $this->commandBus->execute($command);

        return new EmptyResponse();
    }

    private function login(ServerRequestInterface $request): ResponseInterface
    {
        $request = $this->serializer->deserialize($request->getBody()->getContents(), LoginRequest::class);

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
