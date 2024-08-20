<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\QueryExecutor;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\Task\Application\Query\UserProfileByUserId;
use Ramona\Ras2\Task\Application\UserProfileView;

/**
 * @implements Executor<UserProfileView, UserProfileByUserId>
 */
final class UserProfileByUserIdExecutor implements Executor
{
    public function __construct(
        private Connection $connection,
        private Hydrator $hydrator
    ) {
    }

    public function execute(Query $query): mixed
    {
        $raw = $this->connection->fetchAssociative('
            SELECT 
                user_id, 
                (
                    SELECT 
                        json_agg(json_build_object(\'id\', wt.value, \'name\', t.name) )
                    FROM jsonb_array_elements_text(watched_tags) wt(value) 
                        INNER JOIN tags t ON t.id = wt.value::uuid
                ) as watched_tags
            FROM tasks_user_profile
            WHERE user_id=:user_id
        ', [
            'user_id' => $query->userId,
        ]);

        if ($raw === false) {
            throw ProfileNotFound::forUser($query->userId);
        }

        $preformatted = [];
        $preformatted['userId'] = $raw['user_id'];
        $preformatted['watchedTags'] = \Safe\json_decode($raw['watched_tags'] ?? '[]', true);

        return $this->hydrator->hydrate(UserProfileView::class, $preformatted);
    }
}
