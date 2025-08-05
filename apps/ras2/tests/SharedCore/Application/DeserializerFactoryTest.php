<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Application;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\User\Application\Command\LoginRequest;
use Ramona\Ras2\User\Business\UserId;

final class DeserializerFactoryTest extends TestCase
{
    private Deserializer $deserializer;

    protected function setUp(): void
    {
        $container = require __DIR__ . '/../../../src/container.php';
        $this->deserializer = $container->get(Deserializer::class);
    }

    public function testCanDeserializeAString(): void
    {
        /** @phpstan-ignore argument.type */
        $result = $this->deserializer->deserialize('string', '"test"');

        self::assertSame('test', $result);
    }

    public function testCanDeserializeAnInteger(): void
    {
        /** @phpstan-ignore argument.type */
        $result = $this->deserializer->deserialize('integer', '1234');

        self::assertSame(1234, $result);
    }

    public function testCanDeserializeALoginRequest(): void
    {
        $result = $this->deserializer->deserialize(LoginRequest::class, '{"username": "ramona"}');

        self::assertEquals(new LoginRequest('ramona'), $result);
    }

    public function testCanDeserializeAUserId(): void
    {
        $result = $this->deserializer->deserialize(UserId::class, '"01913599-f289-7b0c-a020-9be356dccf0b"');

        self::assertEquals('01913599-f289-7b0c-a020-9be356dccf0b', $result);
    }
}
