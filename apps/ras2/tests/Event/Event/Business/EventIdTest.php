<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Event\Event\Business;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Event\Business\EventId;

final class EventIdTest extends TestCase
{
    public function testFromString(): void
    {
        $eventId = EventId::fromString('0191787b-39db-7bb3-bb09-d8a99fe00b84');

        self::assertEquals('0191787b-39db-7bb3-bb09-d8a99fe00b84', (string) $eventId);
    }
}
