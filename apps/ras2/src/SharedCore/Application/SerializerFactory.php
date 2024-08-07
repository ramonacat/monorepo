<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Application;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Normalizer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\SerializerInterface;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\User\Token;
use Ramona\Ras2\User\UserId;

final class SerializerFactory
{
    public function create(): SerializerInterface
    {
        $normalizer = new Normalizer();
        $normalizer->registerConverter(
            TaskId::class,
            fn (TaskId $t) => (string) $t,
            fn (string $r) => TaskId::fromString($r)
        );
        $normalizer->registerConverter(
            ArrayCollection::class,
            fn (ArrayCollection $a) => $a->toArray(),
            fn (array $a) => new ArrayCollection($a)
        );
        $normalizer->registerConverter(
            UserId::class,
            fn (UserId $u) => (string) $u,
            fn (string $r) => UserId::fromString($r)
        );
        $normalizer->registerConverter(
            Token::class,
            fn (Token $t) => (string) $t,
            fn (string $t) => Token::fromString($t)
        );
        return new Serializer($normalizer);
    }
}
