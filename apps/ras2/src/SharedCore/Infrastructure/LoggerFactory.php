<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure;

use Monolog\Formatter\LineFormatter;
use Monolog\Handler\StreamHandler;
use Monolog\Logger;
use Psr\Log\LoggerInterface;
use Psr\Log\NullLogger;

final class LoggerFactory
{
    public static function create(): LoggerInterface
    {
        $applicationMode = getenv('APPLICATION_MODE');

        if ($applicationMode === 'test') {
            return new NullLogger();
        }

        $logger = new Logger('ras2');
        $handler = new StreamHandler('php://stderr');
        $handler->setFormatter(new LineFormatter(includeStacktraces: true));
        $logger->pushHandler($handler);

        return $logger;
    }
}
