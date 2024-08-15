<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Laminas\Diactoros\Response;
use Psr\Http\Message\ResponseInterface;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;

final class JsonResponseFactory
{
    public function __construct(
        private Serializer $serializer
    ) {
    }

    public function create(mixed $data): ResponseInterface
    {
        $response = new Response(headers: [
            'Content-Type' => 'application/json',
        ]);
        $response->getBody()
            ->write($this->serializer->serialize($data));

        return $response;
    }
}
