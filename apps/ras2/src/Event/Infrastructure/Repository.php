<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Infrastructure;

use Ramona\Ras2\Event\Business\Event;

interface Repository
{
    public function save(Event $event): void;
}
