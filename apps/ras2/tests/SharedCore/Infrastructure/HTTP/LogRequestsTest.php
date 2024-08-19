<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Laminas\Diactoros\Response\EmptyResponse;
use Laminas\Diactoros\ServerRequest;
use Laminas\Diactoros\Uri;
use League\Route\Http\Exception\NotFoundException;
use PHPUnit\Framework\TestCase;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\LogRequests;
use Tests\Ramona\Ras2\LoggerMock;

final class LogRequestsTest extends TestCase
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
                'uri' => $request->getUri(),
                'method' => 'GET',
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

    public function testWillLogResponse(): void
    {
        $loggerMock = new LoggerMock();
        $logExceptions = new LogRequests($loggerMock);
        $result = $logExceptions->process(new ServerRequest(), $this->createRequestHandler(new EmptyResponse()));

        self::assertEquals([
            [
                'level' => 'info',
                'message' => 'Request received',
                'context' => [
                    'uri' => new Uri(),
                    'method' => 'GET',
                ],
            ],
            [
                'level' => 'info',
                'message' => 'Sending response',
                'context' => [
                    'status_code' => 204,
                ],
            ],
        ], $loggerMock->messages);
    }

    private function createRequestHandler(\Exception|ResponseInterface $exception): RequestHandlerInterface
    {
        return new class($exception) implements RequestHandlerInterface {
            public function __construct(
                private \Exception|ResponseInterface $result
            ) {
            }

            public function handle(ServerRequestInterface $request): ResponseInterface
            {
                if ($this->result instanceof \Exception) {
                    throw $this->result;
                }

                return $this->result;
            }
        };
    }
}
