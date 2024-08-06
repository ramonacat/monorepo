<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Serialization;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Serialization\ConversionNotFound;
use Ramona\Ras2\Serialization\Normalizer;
use Tests\Ramona\Ras2\Serialization\Mocks\Simple;
use Tests\Ramona\Ras2\Serialization\Mocks\UnionType;
use Tests\Ramona\Ras2\Serialization\Mocks\UntypedProperty;
use Tests\Ramona\Ras2\Serialization\Mocks\WithChild;

final class NormalizerTest extends TestCase
{
    public function testCanDenormalizeSimpleObject(): void
    {
        $normalizer = new Normalizer();

        $result = $normalizer->denormalize(new Simple());

        self::assertSame([
            'id' => 'test',
            'stuff' => 1234,
        ], $result);
    }

    public function testCanDenormalizeWithAConverter(): void
    {
        $normalizer = new Normalizer();

        $normalizer->registerConverter(Simple::class, fn (Simple $s) => 'simple', fn (string $s) => new Simple());
        $result = $normalizer->denormalize(new WithChild(new Simple(), 123));

        self::assertSame([
            'child' => 'simple',
            'test' => 123,
        ], $result);
    }

    public function testCanNormalizeASimpleObject(): void
    {
        $normalizer = new Normalizer();

        $result = $normalizer->normalize([
            'id' => 'a1234',
            'stuff' => 5678,
        ], Simple::class);

        self::assertEquals(new Simple('a1234', 5678), $result);
    }

    public function testWillSetUntypedPropertyIfNameMatches(): void
    {
        $normalizer = new Normalizer();
        $result = $normalizer->normalize([
            'untyped' => [
                'a',
                'b',
                'c' => 'd',
            ],
        ], UntypedProperty::class);

        self::assertEquals(new UntypedProperty([
            'a',
            'b',
            'c' => 'd',
        ]), $result);
    }

    public function testThrowsOnComplexType(): void
    {
        $normalizer = new Normalizer();

        $this->expectException(ConversionNotFound::class);
        $this->expectExceptionMessage('No conversion found for value "123" of type "float" to "string|float"');

        $normalizer->normalize([
            'field' => 123.0,
        ], UnionType::class);
    }

    public function testCanNormalizeWithAConverter(): void
    {
        $normalizer = new Normalizer();

        $normalizer->registerConverter(
            Simple::class,
            fn (Simple $s) => 'simple',
            fn (array $s) => new Simple('oh', 5555)
        );
        $result = $normalizer->normalize([
            'id' => 'other',
            'stuff' => 555,
        ], Simple::class);

        self::assertEquals(new Simple('oh', 5555), $result);
    }

    public function testCanNormalizeAChildWithAConverter(): void
    {
        $normalizer = new Normalizer();
        $normalizer->registerConverter(
            Simple::class,
            fn (Simple $s) => 'simple',
            fn (string $s) => new Simple('oh', 5432)
        );
        $result = $normalizer->normalize([
            'child' => 'other',
            'test' => 555,
        ], WithChild::class);

        self::assertEquals(new WithChild(new Simple('oh', 5432), 555), $result);
    }

    public function testCanNormalizeAChildWithoutAConverter(): void
    {
        $normalizer = new Normalizer();
        $result = $normalizer->normalize([
            'child' => [
                'id' => 'teest',
                'stuff' => 543,
            ],
            'test' => 5432,
        ], WithChild::class);

        self::assertEquals(new WithChild(new Simple('teest', 543), 5432), $result);
    }

    public function testCannotNormalizeAChildIfKeysAreNotAllStrings(): void
    {
        $normalizer = new Normalizer();

        $this->expectException(ConversionNotFound::class);
        $this->expectExceptionMessage(
            'No conversion found for value "{"id":"teest","stuff":543,"1":2}" of type "array" to "Tests\Ramona\Ras2\Serialization\Mocks\Simple"'
        );
        $normalizer->normalize([
            'child' => [
                'id' => 'teest',
                'stuff' => 543,
                1 => 2,
            ],
            'test' => 5432,
        ], WithChild::class);
    }
}
