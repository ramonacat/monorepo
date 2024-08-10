<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Laminas\Diactoros\Response;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Psr\Log\LoggerInterface;

final class LogExceptions implements MiddlewareInterface
{
    public function __construct(
        private LoggerInterface $logger
    ) {
    }

    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        try {
            return $handler->handle($request);
        } catch (\Exception $e) {
            $this->logger->error('Request failed', [
                'exception' => $e,
            ]);

            $response = new Response();
            $response
                ->getBody()
                ->write(\Safe\json_encode([
                    'status_code' => 500,
                    'reason_phrase' => $e->getMessage(),
                ]));

            $response = $response->withAddedHeader('content-type', 'application/json');

            return $response->withStatus(($e instanceof \League\Route\Http\Exception) ? $e->getStatusCode() : 500);
        }
    }
}
