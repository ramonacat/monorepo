<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Application;

use Ramona\Ras2\System\Business\SystemId;

final readonly class SystemView
{
    public function __construct(
        public SystemId $id,
        public string $hostname,
        public bool $isUpToDate,
        public string $outdatedDescription
    ) {
    }
}
