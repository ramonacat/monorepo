<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application;

use Ramona\Ras2\Task\Business\FilterId;

final readonly class FilterView
{
    public function __construct(
        public FilterId $id,
        public string $name
    ) {
    }
}
