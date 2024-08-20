<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Application;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\User\Application\Command\LoginResponse;
use Ramona\Ras2\User\Application\Session;
use Ramona\Ras2\User\Business\Token;
use Ramona\Ras2\User\Business\UserId;
use Ramsey\Uuid\Uuid;
use Spatie\Snapshots\MatchesSnapshots;

final class SerializerFactoryTest extends TestCase
{
    use MatchesSnapshots;

    private Serializer $serializer;

    protected function setUp(): void
    {
        $container = require __DIR__ . '/../../../src/container.php';
        $this->serializer = $container->get(Serializer::class);
    }

    public function testCanGenerateSerializerThatUnderstandsTaskId(): void
    {
        $taskId = TaskId::generate();

        $result = $this->serializer->serialize($taskId);

        self::assertJsonStringEqualsJsonString(\Safe\json_encode((string) $taskId), $result);
    }

    public function testUnderstandsArrayCollection(): void
    {
        $collection = new ArrayCollection([1, 2, 3]);

        $result = $this->serializer->serialize($collection);

        self::assertJsonStringEqualsJsonString(\Safe\json_encode([1, 2, 3]), $result);
    }

    public function testUnderstandsUserId(): void
    {
        $id = UserId::generate();

        $result = $this->serializer->serialize($id);

        self::assertJsonStringEqualsJsonString(\Safe\json_encode((string) $id), $result);
    }

    public function testUnderstandsToken(): void
    {
        $token = Token::generate();

        $result = $this->serializer->serialize($token);

        self::assertJsonStringEqualsJsonString(\Safe\json_encode((string) $token), $result);
    }

    public function testUnderstandsDateTimeImmutable(): void
    {
        $datetime = \Safe\DateTimeImmutable::createFromFormat('Y-m-d H:i:s', '2024-05-05 05:05:05');

        $result = $this->serializer->serialize($datetime);

        self::assertJsonStringEqualsJsonString(
            \Safe\json_encode([
                'timestamp' => '2024-05-05 05:05:05',
                'timezone' => 'UTC',
            ]),
            $result
        );
    }

    public function testUnderstandsString(): void
    {
        $text = 'test';

        $result = $this->serializer->serialize($text);

        self::assertJsonStringEqualsJsonString('"test"', $result);
    }

    public function testUnderstandsNull(): void
    {
        $result = $this->serializer->serialize(null);

        self::assertJsonStringEqualsJsonString('null', $result);
    }

    public function testUnderstandsUuid(): void
    {
        $uuid = Uuid::uuid7();
        $result = $this->serializer->serialize($uuid);

        self::assertJsonStringEqualsJsonString("\"{$uuid}\"", $result);
    }

    public function testUnderstandsTaskView(): void
    {
        $taskView = new TaskView(
            TaskId::fromString('01913564-5b13-7867-93bc-fcb4649456f1'),
            'Some title',
            null,
            null,
            new ArrayCollection(['tag1', 'tag2']),
            null,
            new ArrayCollection()
        );

        $result = $this->serializer->serialize($taskView);

        $this->assertMatchesJsonSnapshot($result);
    }

    public function testUnderstandsLoginResponse(): void
    {
        $loginResponse = new LoginResponse(Token::fromString(
            'xGl8rnQidHJ0ih37Svzknzu4ZkXiuhmNDP6EqL7X2fnT0EIBvmnXWtAZVBt/8ESoNZmswKhXniyPU9DHGmIR9Q=='
        ));
        $result = $this->serializer->serialize($loginResponse);

        $this->assertMatchesJsonSnapshot($result);
    }

    public function testUnderstandsSession(): void
    {
        $session = new Session(
            UserId::fromString('01913763-3947-73e2-9406-b7efbcf560b3'),
            'ramona',
            new \DateTimeZone('Europe/Berlin')
        );

        $result = $this->serializer->serialize($session);

        $this->assertMatchesJsonSnapshot($result);
    }
}
