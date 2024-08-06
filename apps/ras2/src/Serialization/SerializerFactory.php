<?php

declare(strict_types=1);

namespace Ramona\Ras2\Serialization;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\Task\TaskId;

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
        return new Serializer($normalizer);
    }
}
