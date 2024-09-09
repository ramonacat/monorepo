<?php
declare(strict_types=1);

use Psr\Container\ContainerInterface;
use Ramona\Ras2\Music\Application\Command\ScanLibrary;
use Ramona\Ras2\Music\Business\LibraryId;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;

require_once __DIR__.'/../vendor/autoload.php';

/** @var ContainerInterface $container */
$container = require __DIR__ .'/../src/container.php';

/**
 * @var CommandBus $commandBus
 */
$commandBus = $container->get(CommandBus::class);

$commandBus->execute(new ScanLibrary(LibraryId::fromString('0191c63f-e997-777a-95a7-c1cfdfa93dbc')));

