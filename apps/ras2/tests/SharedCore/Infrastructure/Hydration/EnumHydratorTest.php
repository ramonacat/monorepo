<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\Hydration;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\CannotHydrateType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\EnumHydrator;

final class EnumHydratorTest extends TestCase
{
    public function testCanHydrateEnum(): void
    {
        $hydrator = new EnumHydrator(TestEnum::class);

        $result = $hydrator->hydrate(new Hydrator(), 'TEST1', []);

        self::assertEquals(TestEnum::TEST1, $result);
    }

    public function testThrowsOnInvalidValue(): void
    {
        $hydrator = new EnumHydrator(TestEnum::class);

        $this->expectException(CannotHydrateType::class);
        $hydrator->hydrate(new Hydrator(), 'TEST2000', []);

    }
}
