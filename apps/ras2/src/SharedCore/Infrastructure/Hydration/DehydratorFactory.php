<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\ArrayCollectionDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\DateTimeImmutableDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\DateTimeZoneDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\ScalarDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\UuidDehydrator;

final class DehydratorFactory
{
    public static function create(): Dehydrator
    {
        $dehydrator = new DefaultDehydrator();
        $dehydrator->installValueDehydrator(new ArrayCollectionDehydrator());
        $dehydrator->installValueDehydrator(new ScalarDehydrator('integer'));
        $dehydrator->installValueDehydrator(new ScalarDehydrator('string'));
        $dehydrator->installValueDehydrator(new ScalarDehydrator('boolean'));
        $dehydrator->installValueDehydrator(new ScalarDehydrator('NULL'));
        $dehydrator->installValueDehydrator(new UuidDehydrator());
        $dehydrator->installValueDehydrator(new DateTimeImmutableDehydrator());
        $dehydrator->installValueDehydrator(new DateTimeZoneDehydrator());

        return $dehydrator;
    }
}
