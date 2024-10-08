<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\Hydration;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\DefaultHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ScalarHydrator;

final class ScalarHydratorTest extends TestCase
{
    public function testCanHydrateNull(): void
    {
        $hydrator = new ScalarHydrator('NULL');

        self::assertNull($hydrator->hydrate(new DefaultHydrator(), null, []));
    }

    public function testCanHydrateInteger(): void
    {
        $hydrator = new ScalarHydrator('integer');

        self::assertEquals(123, $hydrator->hydrate(new DefaultHydrator(), 123, []));
    }
}
