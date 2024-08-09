<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Application;

use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ArrayCollectionDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DateTimeImmutableDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultSerializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ObjectDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ScalarDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\UuidDehydrator;
use Ramona\Ras2\Task\TaskIdDehydrator;
use Ramona\Ras2\Task\TaskView;
use Ramona\Ras2\User\Command\LoginResponse;
use Ramona\Ras2\User\Session;
use Ramona\Ras2\User\TokenDehydrator;
use Ramona\Ras2\User\UserIdDehydrator;

final class SerializerFactory
{
    public function create(): Serializer
    {
        $dehydrator = new DefaultDehydrator();
        $dehydrator->installValueDehydrator(new ArrayCollectionDehydrator());
        $dehydrator->installValueDehydrator(new ScalarDehydrator('integer'));
        $dehydrator->installValueDehydrator(new ScalarDehydrator('string'));
        $dehydrator->installValueDehydrator(new ScalarDehydrator('NULL'));
        $dehydrator->installValueDehydrator(new UuidDehydrator());
        $dehydrator->installValueDehydrator(new UserIdDehydrator());
        $dehydrator->installValueDehydrator(new DateTimeImmutableDehydrator());
        $dehydrator->installValueDehydrator(new TokenDehydrator());
        $dehydrator->installValueDehydrator(new TaskIdDehydrator());
        $dehydrator->installValueDehydrator(new ObjectDehydrator(TaskView::class));
        $dehydrator->installValueDehydrator(new ObjectDehydrator(LoginResponse::class));
        $dehydrator->installValueDehydrator(new ObjectDehydrator(Session::class));

        return new DefaultSerializer($dehydrator);
    }
}
