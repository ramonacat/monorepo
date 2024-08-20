<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Business;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\Task\Business\TagId;
use Ramona\Ras2\User\Business\UserId;

final class UserProfile
{
    /**
     * @param ArrayCollection<int, TagId> $watchedTags
     */
    public function __construct(
        private UserId $userId,
        private ArrayCollection $watchedTags
    ) {
    }

    public function userId(): UserId
    {
        return $this->userId;
    }

    /**
     * @return ArrayCollection<int, TagId>
     */
    public function watchedTags(): ArrayCollection
    {
        return $this->watchedTags;
    }
}
