<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Application;

use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ArrayCollectionHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultDeserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ObjectHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ScalarHydrator;
use Ramona\Ras2\Task\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Command\UpsertIdea;
use Ramona\Ras2\Task\TaskIdHydrator;
use Ramona\Ras2\User\Command\LoginRequest;
use Ramona\Ras2\User\UserIdHydrator;

final class DeserializerFactory
{
    public function create(): Deserializer
    {
        $hydrator = new Hydrator();
        $hydrator->installValueHydrator(new ScalarHydrator('string'));
        $hydrator->installValueHydrator(new ScalarHydrator('integer'));
        $hydrator->installValueHydrator(new ObjectHydrator(LoginRequest::class));
        $hydrator->installValueHydrator(new ObjectHydrator(UpsertBacklogItem::class));
        $hydrator->installValueHydrator(new ObjectHydrator(UpsertIdea::class));
        $hydrator->installValueHydrator(new TaskIdHydrator());
        $hydrator->installValueHydrator(new ArrayCollectionHydrator());
        $hydrator->installValueHydrator(new UserIdHydrator());

        return new DefaultDeserializer($hydrator);
    }
}
