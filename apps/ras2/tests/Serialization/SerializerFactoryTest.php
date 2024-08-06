<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Serialization;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Serialization\SerializerFactory;
use Ramona\Ras2\Task\TaskId;

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
}
