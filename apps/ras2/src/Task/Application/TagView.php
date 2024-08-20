<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application;

use Ramona\Ras2\Task\Business\TagId;

final readonly class TagView
{
    public function __construct(
        public TagId $id,
        public string $name
    ) {
    }
}
