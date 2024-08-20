<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueType;
use Ramona\Ras2\User\Business\UserId;

final class UserProfileView
{
    /**
     * @param ArrayCollection<int, TagView> $watchedTags
     */
    public function __construct(
        public UserId $userId,
        #[KeyType('integer')]
        #[ValueType(TagView::class)]
        public ArrayCollection $watchedTags
    ) {
    }
}
