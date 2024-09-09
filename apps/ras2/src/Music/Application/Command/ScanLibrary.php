<?php

declare(strict_types=1);

namespace Ramona\Ras2\Music\Application\Command;

use Ramona\Ras2\Music\Business\LibraryId;
use Ramona\Ras2\Music\Infrastructure\CommandExectuor\ScanLibraryExecutor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;

#[ExecutedBy(ScanLibraryExecutor::class)]
final readonly class ScanLibrary implements \Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command
{
    public function __construct(
        public LibraryId $id
    ) {
    }
}
