<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Laminas\Diactoros\ServerRequest;
use League\Route\Http\Exception\NotFoundException;
use PHPUnit\Framework\TestCase;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\LogRequests;
use Tests\Ramona\Ras2\LoggerMock;

final class LogExceptionsTest extends TestCase
{
    public function testWillLogTheException(): void
    {
        $loggerMock = new LoggerMock();
        $logExceptions = new LogRequests($loggerMock);
        $exception = new \RuntimeException('woops');
        $request = new ServerRequest();
        $logExceptions->process($request, $this->createRequestHandler($exception));

        self::assertEquals([[
            'level' => 'info',
            'message' => 'Request received',
            'context' => [
                'request' => $request,
            ],
        ],
            [
                'level' => 'error',
                'message' => 'Request failed',
                'context' => [
                    'exception' => $exception,
                ],
            ],
        ], $loggerMock->messages);
    }

    public function testWillSetResponseBody(): void
    {
        $loggerMock = new LoggerMock();
        $logExceptions = new LogRequests($loggerMock);
        $exception = new \RuntimeException('woops');
        $result = $logExceptions->process(new ServerRequest(), $this->createRequestHandler($exception));

        $body = $result->getBody();
        $body->seek(0);

        self::assertJsonStringEqualsJsonString(
            '{"reason_phrase": "woops", "status_code": 500}',
            $body->getContents()
        );
        self::assertEquals(500, $result->getStatusCode());
    }

    public function testWillSetStatusCodeFromLeagueException(): void
    {
        $loggerMock = new LoggerMock();
        $logExceptions = new LogRequests($loggerMock);
        $exception = new NotFoundException();
        $result = $logExceptions->process(new ServerRequest(), $this->createRequestHandler($exception));

        self::assertEquals(404, $result->getStatusCode());
    }

    private function createRequestHandler(\Exception $exception): RequestHandlerInterface
    {
        return new class($exception) implements RequestHandlerInterface {
            public function __construct(
                private \Exception $exception
            ) {
            }

            public function handle(ServerRequestInterface $request): ResponseInterface
            {
                throw $this->exception;
            }
        };
    }
}
