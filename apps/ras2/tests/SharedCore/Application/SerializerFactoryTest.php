<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Infrastructure\Application;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Application\SerializerFactory;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\Task\TaskView;
use Ramona\Ras2\User\Command\LoginResponse;
use Ramona\Ras2\User\Token;
use Ramona\Ras2\User\UserId;
use Ramsey\Uuid\Uuid;
use Spatie\Snapshots\MatchesSnapshots;

final class SerializerFactoryTest extends TestCase
{
    use MatchesSnapshots;

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

    public function testUnderstandsDateTimeImmutable(): void
    {
        $datetime = \Safe\DateTimeImmutable::createFromFormat('Y-m-d H:i:s', '2024-05-05 05:05:05');

        $serializer = (new SerializerFactory())->create();

        $result = $serializer->serialize($datetime);

        self::assertJsonStringEqualsJsonString(
            \Safe\json_encode([
                'timestamp' => 1714885505,
                'timezone' => 'UTC',
            ]),
            $result
        );
    }

    public function testUnderstandsString(): void
    {
        $text = 'test';

        $serializer = (new SerializerFactory())->create();

        $result = $serializer->serialize($text);

        self::assertJsonStringEqualsJsonString('"test"', $result);
    }

    public function testUnderstandsNull(): void
    {
        $serializer = (new SerializerFactory())->create();

        $result = $serializer->serialize(null);

        self::assertJsonStringEqualsJsonString('null', $result);
    }

    public function testUnderstandsUuid(): void
    {
        $serializer = (new SerializerFactory())->create();

        $uuid = Uuid::uuid7();
        $result = $serializer->serialize($uuid);

        self::assertJsonStringEqualsJsonString("\"{$uuid}\"", $result);
    }

    public function testUnderstandsTaskView(): void
    {
        $taskView = new TaskView(
            TaskId::fromString('01913564-5b13-7867-93bc-fcb4649456f1'),
            'Some title',
            null,
            new ArrayCollection(['tag1', 'tag2']),
            null
        );

        $serializer = (new SerializerFactory())->create();
        $result = $serializer->serialize($taskView);

        $this->assertMatchesJsonSnapshot($result);
    }

    public function testUnderstandsLoginResponse(): void
    {
        $loginResponse = new LoginResponse(Token::fromString(
            'xGl8rnQidHJ0ih37Svzknzu4ZkXiuhmNDP6EqL7X2fnT0EIBvmnXWtAZVBt/8ESoNZmswKhXniyPU9DHGmIR9Q=='
        ));
        $serializer = (new SerializerFactory())->create();
        $result = $serializer->serialize($loginResponse);

        $this->assertMatchesJsonSnapshot($result);
    }
}
