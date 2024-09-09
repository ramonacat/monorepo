<?php

declare(strict_types=1);

namespace Ramona\Ras2\Music\Application\Command;

use Ramona\Ras2\Music\Business\LibraryId;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;

final readonly class AddLibrary implements Command
{
    public function __construct(
        public LibraryId $id,
        public string $path
    ) {
    }
}
