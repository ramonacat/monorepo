<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\Event\Business\UserProfile;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;

final class PostgresUserProfileRepository implements UserProfileRepository
{
    public function __construct(
        private Connection $connection,
        private Serializer $serializer
    ) {
    }

    public function save(UserProfile $profile): void
    {
        $this->connection->executeStatement('
            INSERT INTO tasks_user_profile(user_id, watched_tags) 
                VALUES (:user_id, :watched_tasks) 
            ON CONFLICT (user_id) DO UPDATE SET watched_tags=:watched_tasks
        ', [
            'user_id' => $profile->userId(),
            'watched_tasks' => $this->serializer->serialize($profile->watchedTags()),
        ]);
    }
}
