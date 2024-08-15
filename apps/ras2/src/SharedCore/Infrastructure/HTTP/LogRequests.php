<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Laminas\Diactoros\Response;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Psr\Log\LoggerInterface;

final class LogRequests implements MiddlewareInterface
{
    public function __construct(
        private LoggerInterface $logger
    ) {
    }

    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        try {
            $this->logger->info('Request received', [
                'request' => $request,
            ]);
            $response = $handler->handle($request);
            $this->logger->info('Sending response', [
                'response' => $response,
            ]);
            return $response;
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
