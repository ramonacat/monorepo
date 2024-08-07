<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Infrastructure;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Infrastructure\SerializerFactory;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\User\Token;
use Ramona\Ras2\User\UserId;

final class SerializerFactoryTest extends TestCase
{
    public function testCanGenerateSerializerThatUnderstandsTaskId(): void
    {
        $taskId = TaskId::generate();

        $serializer = (new SerializerFactory())->create();

        $result = $serializer->serialize($taskId);

        self::assertJsonStringEqualsJsonString(\Safe\json_encode((string) $taskId), $result);
    }

    public function testUnderstandsArrayCollection(): void
    {
        $collection = new ArrayCollection([1, 2, 3]);

        $serializer = (new SerializerFactory())->create();

        $result = $serializer->serialize($collection);

        self::assertJsonStringEqualsJsonString(\Safe\json_encode([1, 2, 3]), $result);
    }

    public function testUnderstandsUserId(): void
    {
        $id = UserId::generate();

        $serializer = (new SerializerFactory())->create();

        $result = $serializer->serialize($id);

        self::assertJsonStringEqualsJsonString(\Safe\json_encode((string) $id), $result);
    }

    public function testUnderstandsToken(): void
    {
        $token = Token::generate();

        $serializer = (new SerializerFactory())->create();

        $result = $serializer->serialize($token);

        self::assertJsonStringEqualsJsonString(\Safe\json_encode((string) $token), $result);
    }
}
