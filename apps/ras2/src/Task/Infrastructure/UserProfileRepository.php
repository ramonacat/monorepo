<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure;

use Ramona\Ras2\Event\Business\UserProfile;

interface UserProfileRepository
{
    public function save(UserProfile $profile): void;
}
