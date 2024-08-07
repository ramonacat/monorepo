<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Infrastructure\Infrastructure\Serialization;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ConversionNotFound;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\MissingDataForField;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Normalizer;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\Simple;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\UnionType;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\UntypedProperty;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\WithChild;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\WithNullableChild;

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
        $result = $normalizer->denormalize(new WithNullableChild(new Simple(), 123));

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
        ], WithNullableChild::class);

        self::assertEquals(new WithNullableChild(new Simple('oh', 5432), 555), $result);
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
        ], WithNullableChild::class);

        self::assertEquals(new WithNullableChild(new Simple('teest', 543), 5432), $result);
    }

    public function testCannotNormalizeAChildIfKeysAreNotAllStrings(): void
    {
        $normalizer = new Normalizer();

        $this->expectException(ConversionNotFound::class);
        $this->expectExceptionMessage(
            'No conversion found for value "{"id":"teest","stuff":543,"1":2}" of type "array" to "Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\Simple"'
        );
        $normalizer->normalize([
            'child' => [
                'id' => 'teest',
                'stuff' => 543,
                1 => 2,
            ],
            'test' => 5432,
        ], WithNullableChild::class);
    }

    public function testCanSetNullInDenormalisation(): void
    {
        $normalizer = new Normalizer();

        $result = $normalizer->denormalize(new WithNullableChild(null, 123));

        self::assertEquals([
            'child' => null,
            'test' => 123,
        ], $result);
    }

    public function testWillThrowIfNotAllFieldsCanBeInitialized(): void
    {
        $normalizer = new Normalizer();

        $this->expectException(MissingDataForField::class);
        $normalizer->normalize([
            'child' => [
                'id' => 'a',
            ],
        ], WithNullableChild::class);
    }

    public function testWillThrowIfFieldIsNotNullableButNullIsProvided(): void
    {
        $normalizer = new Normalizer();

        $this->expectException(MissingDataForField::class);
        $normalizer->normalize([
            'child' => [
                'id' => '123',
                'stuff' => null,
            ],
            'test' => null,
        ], WithNullableChild::class);
    }

    public function testWillThrowIfFieldIsNotNullableButNullIsProvidedClassVariant(): void
    {
        $normalizer = new Normalizer();

        $this->expectException(MissingDataForField::class);
        $normalizer->normalize([
            'child' => null,
        ], WithChild::class);
    }

    public function testWillThrowOnResource(): void
    {
        $normalizer = new Normalizer();

        $this->expectException(ConversionNotFound::class);
        $this->expectExceptionMessageMatches(
            '/No conversion found for value "(.*)" of type "resource \\(stream\\)" to ""/'
        );
        $normalizer->denormalize(new UntypedProperty(\Safe\tmpfile()));
    }

    public function testWillSetNullablePropertyToNullBuiltinType(): void
    {
        $normalizer = new Normalizer();

        $result = $normalizer->normalize([
            'id' => 'stuff',
            'stuff' => null,
        ], Simple::class);

        self::assertNull($result->stuff);
    }

    public function testWillSetNullablePropertyToNull(): void
    {
        $normalizer = new Normalizer();

        $result = $normalizer->normalize([
            'child' => null,
            'test' => 123,
        ], WithNullableChild::class);

        self::assertNull($result->child);
        self::assertSame(123, $result->test);
    }
}
