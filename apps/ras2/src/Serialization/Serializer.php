<?php

declare(strict_types=1);

namespace Ramona\Ras2\Serialization;

final class Serializer implements SerializerInterface
{
    public function __construct(
        private Normalizer $normalizer
    ) {
    }

    public function serialize(object $data): string
    {
        return \Safe\json_encode($this->normalizer->denormalize($data));
    }

    /**
     * @template T of object
     * @param class-string<T> $className
     * @return T
     */
    public function deserialize(string $data, string $className): object
    {
        /** @var array<string, mixed> $rawArray */
        $rawArray = \Safe\json_decode($data, true);
        return $this->normalizer->normalize($rawArray, $className);
    }
}
