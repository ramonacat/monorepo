<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Application;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Application\DeserializerFactory;
use Ramona\Ras2\Task\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Command\UpsertIdea;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\User\Command\LoginRequest;
use Ramona\Ras2\User\UserId;

final class DeserializerFactoryTest extends TestCase
{
    private \Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer $deserializer;

    protected function setUp(): void
    {
        $this->deserializer = (new DeserializerFactory())->create();
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

    public function testCanDeserializeUpsertBacklogItem(): void
    {
        $raw = [
            'id' => '01913599-f289-7b0c-a020-9be356dccf0b',
            'title' => 'test',
            'tags' => ['a', 'b', 'c'],
            'assignee' => null,
            'deadline' => null,
        ];

        $raw = \Safe\json_encode($raw);

        $result = $this->deserializer->deserialize(UpsertBacklogItem::class, $raw);

        self::assertEquals(
            new UpsertBacklogItem(
                TaskId::fromString('01913599-f289-7b0c-a020-9be356dccf0b'),
                'test',
                new ArrayCollection(['a', 'b', 'c']),
                null,
                null
            ),
            $result
        );
    }

    public function testCanDeserializeUpsertIdea(): void
    {
        $raw = [
            'id' => '01913599-f289-7b0c-a020-9be356dccf0b',
            'title' => 'test',
            'tags' => ['a', 'b', 'c'],
        ];

        $raw = \Safe\json_encode($raw);

        $result = $this->deserializer->deserialize(UpsertIdea::class, $raw);

        self::assertEquals(
            new UpsertIdea(
                TaskId::fromString('01913599-f289-7b0c-a020-9be356dccf0b'),
                'test',
                new ArrayCollection(['a', 'b', 'c']),
            ),
            $result
        );
    }

    public function testCanDeserializeAUserId(): void
    {
        $result = $this->deserializer->deserialize(UserId::class, '"01913599-f289-7b0c-a020-9be356dccf0b"');

        self::assertEquals('01913599-f289-7b0c-a020-9be356dccf0b', $result);
    }
}
