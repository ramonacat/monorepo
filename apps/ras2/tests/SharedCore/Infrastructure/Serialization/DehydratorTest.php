<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\CannotDehydrateType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\DefaultDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\ObjectDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\ScalarDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueDehydrator;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\DeepInheritance\A;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\DeepInheritance\B;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\Simple;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\SimpleInterface;

final class DehydratorTest extends TestCase
{
    private DefaultDehydrator $dehydrator;

    protected function setUp(): void
    {
        $this->dehydrator = new DefaultDehydrator();
        $this->dehydrator->installValueDehydrator(new ScalarDehydrator('string'));
        $this->dehydrator->installValueDehydrator(new ScalarDehydrator('integer'));
    }

    public function testCanDehydrateByInterface(): void
    {
        $this->dehydrator->installValueDehydrator(new ObjectDehydrator(SimpleInterface::class));

        $result = $this->dehydrator->dehydrate(new Simple());

        self::assertEquals([
            'id' => 'test',
            'stuff' => 1234,
        ], $result);
    }

    public function testCanDehydrateByParentClass(): void
    {
        $this->dehydrator->installValueDehydrator(new ObjectDehydrator(Mocks\DeepInheritance\A::class));

        $result = $this->dehydrator->dehydrate(new Mocks\DeepInheritance\C());

        self::assertEquals([
            'test' => 54321,
        ], $result);
    }

    public function testCanDehydrateObjectsWithoutExplicitDehydrator(): void
    {
        $result = $this->dehydrator->dehydrate(new Simple());

        self::assertEquals([
            'id' => 'test',
            'stuff' => 1234,
        ], $result);
    }

    public function testThrowsOnMissingDehydratorForAScalar(): void
    {
        $this->expectException(CannotDehydrateType::class);
        $this->expectExceptionMessage('Cannot dehydrate type \'resource\'');
        $this->dehydrator->dehydrate(\Safe\tmpfile());
    }

    public function testCanDehydrateSpecificClass(): void
    {
        $this->dehydrator->installValueDehydrator(new ObjectDehydrator(A::class));
        $this->dehydrator->installValueDehydrator(new class() implements ValueDehydrator {
            public function dehydrate(Dehydrator $dehydrator, mixed $value): mixed
            {
                return 'B CALLED';
            }

            /**
             * @return class-string
             */
            public function handles(): string
            {
                return B::class;
            }
        });

        $result = $this->dehydrator->dehydrate(new B());

        self::assertSame('B CALLED', $result);
    }

    public function testWillThrowOnAMissingDehydratorForScalar(): void
    {
        $this->expectException(CannotDehydrateType::class);
        $this->dehydrator->dehydrate(1.23);
    }
}
