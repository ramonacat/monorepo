<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Laminas\Diactoros\ServerRequest;
use PHPUnit\Framework\TestCase;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\LogExceptions;
use Tests\Ramona\Ras2\LoggerMock;

final class LogExceptionsTest extends TestCase
{
    public function testWillLogTheException(): void
    {
        $loggerMock = new LoggerMock();
        $logExceptions = new LogExceptions($loggerMock);
        $exception = new \RuntimeException('woops');
        $logExceptions->process(new ServerRequest(), $this->createRequestHandler($exception));

        self::assertEquals([[
            'level' => 'error',
            'message' => 'Request failed',
            'context' => [
                'exception' => $exception,
            ],
        ]], $loggerMock->messages);
    }

    public function testWillSetResponseBody(): void
    {
        $loggerMock = new LoggerMock();
        $logExceptions = new LogExceptions($loggerMock);
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

    public function createRequestHandler(\RuntimeException $exception): RequestHandlerInterface
    {
        return new class($exception) implements RequestHandlerInterface {
            public function __construct(
                private \RuntimeException $exception
            ) {
            }

            public function handle(ServerRequestInterface $request): ResponseInterface
            {
                throw $this->exception;
            }
        };
    }
}
