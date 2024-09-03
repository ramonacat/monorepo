<?php
declare(strict_types=1);

use Psr\Container\ContainerInterface;
use Ramona\Ras2\Maintenance\Application\Command\CleanupTelegrafDatabase;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;

require_once __DIR__.'/../vendor/autoload.php';

/** @var ContainerInterface $container */
$container = require __DIR__ .'/../src/container.php';

$container->get(CommandBus::class)->execute(new CleanupTelegrafDatabase());