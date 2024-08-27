<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ArrayCollectionHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\DateTimeImmutableHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\DateTimeZoneHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ScalarHydrator;

final class HydratorFactory
{
    public static function create(): Hydrator
    {
        $hydrator = new DefaultHydrator();
        $hydrator->installValueHydrator(new ScalarHydrator('string'));
        $hydrator->installValueHydrator(new ScalarHydrator('integer'));
        $hydrator->installValueHydrator(new ScalarHydrator('boolean'));
        $hydrator->installValueHydrator(new ArrayCollectionHydrator());
        $hydrator->installValueHydrator(new DateTimeImmutableHydrator());
        $hydrator->installValueHydrator(new DateTimeZoneHydrator());

        return $hydrator;
    }
}
