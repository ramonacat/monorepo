<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueType;
use Ramona\Ras2\User\Business\UserId;

final readonly class Filter
{
    /**
     * @param ArrayCollection<int, UserId> $assignees
     * @param ArrayCollection<int, TagId> $tags
     */
    public function __construct(
        private FilterId $id,
        private string $name,
        #[KeyType('integer'),
            ValueType(UserId::class)]
        private ArrayCollection $assignees,
        #[KeyType('integer'),
            ValueType(TagId::class)]
        private ArrayCollection $tags,
    ) {
    }

    public function id(): FilterId
    {
        return $this->id;
    }

    public function name(): string
    {
        return $this->name;
    }

    /**
     * @return ArrayCollection<int, UserId>
     */
    public function assignees(): ArrayCollection
    {
        return $this->assignees;
    }

    /**
     * @return ArrayCollection<int, TagId>
     */
    public function tags(): ArrayCollection
    {
        return $this->tags;
    }
}
