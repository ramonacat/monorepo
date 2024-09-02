<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Infrastructure;

use Closure;
use Ramona\Ras2\System\Business\System;

interface Repository
{
    public function insert(System $system): void;

    public function save(System $system): void;

    public function getByHostname(string $hostname): System;

    /**
     * @param Closure():void $param
     */
    public function transactional(Closure $param): void;
}
