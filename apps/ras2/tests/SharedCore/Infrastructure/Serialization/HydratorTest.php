<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ArrayCollectionHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\CannotHydrateType;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\InvalidArrayDeclaration;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\MissingInputValue;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ObjectHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ScalarHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ValueHydrator;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\InvalidAnnotations\ArrayCollectionWithoutAttributes;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\InvalidAnnotations\ArrayCollectionWithoutKey;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\InvalidAnnotations\ArrayCollectionWithoutValue;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\Simple;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\UnionType;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\WithArrayCollection;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\WithChild;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\WithNullableChild;

final class HydratorTest extends TestCase
{
    private Hydrator $hydrator;

    protected function setUp(): void
    {
        $this->hydrator = new Hydrator();
        $this->hydrator->installValueHydrator(new ArrayCollectionHydrator());
        $this->hydrator->installValueHydrator(new ScalarHydrator('integer'));
        $this->hydrator->installValueHydrator(new ScalarHydrator('string'));
    }

    public function testArrayCollectionHydrationIgnoresUnrelatedAttributes(): void
    {
        $this->hydrator->installValueHydrator(new ObjectHydrator(WithArrayCollection::class));

        $result = $this->hydrator->hydrate(WithArrayCollection::class, [
            'things' => ['t', 'e', 'st'],
        ]);

        $expected = new WithArrayCollection();
        $expected->things = new ArrayCollection(['t', 'e', 'st']);

        self::assertEquals($expected, $result);
    }

    /**
     * @param class-string $className
     * @param array<mixed> $rawData
     */
    #[DataProvider('dataThrowsOnInvalidArrayCollection')]
    public function testThrowsOnInvalidArrayCollection(string $className, array $rawData): void
    {
        $this->hydrator->installValueHydrator(new ObjectHydrator($className));
        $this->expectException(InvalidArrayDeclaration::class);
        $this->expectExceptionMessage('Property declaration is missing key or value');
        $this->hydrator->hydrate($className, $rawData);
    }

    /**
     * @return iterable<array{0:class-string, 1:array<mixed>}>
     */
    public static function dataThrowsOnInvalidArrayCollection(): iterable
    {
        yield [
            ArrayCollectionWithoutKey::class, [
                'things' => 1234,
            ]];
        yield [
            ArrayCollectionWithoutValue::class, [
                'things' => 1234,
            ]];
        yield [
            ArrayCollectionWithoutAttributes::class, [
                'things' => 1234,
            ]];
    }

    public function testFailsOnUnionType(): void
    {
        $this->hydrator->installValueHydrator(new ObjectHydrator(UnionType::class));

        $this->expectException(CannotHydrateType::class);
        $this->expectExceptionMessage("Cannot hydrate type 'string|float'");
        $this->hydrator->hydrate(UnionType::class, [
            'types' => 123,
        ]);
    }

    public function testWillNotPassUnrelatedAttributes(): void
    {
        $this->hydrator->installValueHydrator(new ObjectHydrator(WithArrayCollection::class));
        $valueHydrator = new class() implements ValueHydrator {
            /**
             * @var array<object>
             */
            public array $attributes = [];

            public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
            {
                $this->attributes = $serializationAttributes;

                return new ArrayCollection($input);
            }

            public function handles(): string
            {
                return ArrayCollection::class;
            }
        };
        $this->hydrator->installValueHydrator($valueHydrator);

        $this->hydrator->hydrate(WithArrayCollection::class, [
            'things' => ['a'],
        ]);

        self::assertCount(2, $valueHydrator->attributes);
    }

    public function testWillSetANullablePropertyToNull(): void
    {
        $this->hydrator->installValueHydrator(new ObjectHydrator(WithNullableChild::class));

        $result = $this->hydrator->hydrate(WithNullableChild::class, [
            'child' => null,
            'test' => 1234,
        ]);

        self::assertEquals(new WithNullableChild(null, 1234), $result);
    }

    public function testThrowOnNullForNonNullableProperty(): void
    {
        $this->hydrator->installValueHydrator(new ObjectHydrator(WithChild::class));
        $this->hydrator->installValueHydrator(new ObjectHydrator(Simple::class));

        $this->expectException(CannotHydrateType::class);
        $this->expectExceptionMessage("Cannot hydrate type 'null'");
        $this->hydrator->hydrate(WithChild::class, [
            'child' => null,
            'test' => 1234,
        ]);
    }

    public function testThrowsOnMissingHydrator(): void
    {
        $this->expectException(CannotHydrateType::class);
        $this->expectExceptionMessage(
            "Cannot hydrate type 'Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\Simple'"
        );

        $this->hydrator->hydrate(Simple::class, [
            'test' => 1234,
        ]);
    }

    public function testThrowsOnMissingValue(): void
    {
        $this->hydrator->installValueHydrator(new ObjectHydrator(Simple::class));

        $this->expectException(MissingInputValue::class);
        $this->expectExceptionMessage("No value was provided for field 'id'");
        $this->hydrator->hydrate(Simple::class, []);
    }
}
