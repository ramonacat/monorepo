<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2;

use Psr\Log\LoggerInterface;
use Psr\Log\LoggerTrait;
use Stringable;

final class LoggerMock implements LoggerInterface
{
    use LoggerTrait;

    /**
     * @var list<array{level:mixed, message:string,context:array<mixed>}>
     */
    public array $messages = [];

    public function log(mixed $level, Stringable|string $message, array $context = []): void
    {
        $this->messages[] = [
            'level' => $level,
            'message' => (string) $message,
            'context' => $context,
        ];
    }
}
