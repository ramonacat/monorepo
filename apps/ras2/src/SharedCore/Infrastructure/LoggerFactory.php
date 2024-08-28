<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure;

use Monolog\Formatter\LineFormatter;
use Monolog\Handler\StreamHandler;
use Monolog\Handler\SyslogHandler;
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
        if ($applicationMode !== 'prod') {
            $handler = new StreamHandler('php://stderr');
            $handler->setFormatter(new LineFormatter(includeStacktraces: true));
        } else {
            $handler = new SyslogHandler('ras2');
        }
        $logger->pushHandler($handler);

        return $logger;
    }
}
