<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Infrastructure;

use Ramona\Ras2\Event\Business\EventId;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueDehydrator;

/**
 * @implements ValueDehydrator<EventId>
 */
final class EventIdDehydrator implements ValueDehydrator
{
    public function dehydrate(Dehydrator $dehydrator, mixed $value): mixed
    {
        return (string) $value;
    }

    public function handles(): string
    {
        return EventId::class;
    }
}
