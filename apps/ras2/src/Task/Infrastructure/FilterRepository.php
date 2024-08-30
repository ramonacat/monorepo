<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure;

use Ramona\Ras2\Task\Business\Filter;

interface FilterRepository
{
    public function upsert(Filter $filter): void;
}
