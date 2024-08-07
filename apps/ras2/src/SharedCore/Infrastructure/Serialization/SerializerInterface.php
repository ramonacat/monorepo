<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

interface SerializerInterface
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function serialize(object $data): string;

    /**
     * @template T of object
     * @param class-string<T> $className
     * @return T
     */
    public function deserialize(string $data, string $className): object;
}
