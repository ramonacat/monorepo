<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

interface Repository
{
    public function save(Task $task): void;

    /**
     * @param array<int, string> $tags
     * @return array<int, TagId>
     */
    public function fetchOrCreateTags(array $tags): array;

    /**
     * @param \Closure():void $action
     */
    public function transactional(\Closure $action): void;
}
