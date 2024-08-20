<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Ramona\Ras2\Event\Business\UserProfile;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\Task\Application\Command\UpsertUserProfile;
use Ramona\Ras2\Task\Infrastructure\Repository;
use Ramona\Ras2\Task\Infrastructure\UserProfileRepository;

/**
 * @implements Executor<UpsertUserProfile>
 */
final class UpsertUserProfileExecutor implements Executor
{
    public function __construct(
        private UserProfileRepository $userProfileRepository,
        private Repository $repository
    ) {
    }

    public function execute(Command $command): void
    {
        $tags = $this->repository->fetchOrCreateTags($command->watchedTags);
        $userProfile = new UserProfile($command->userId, $tags);

        $this->userProfileRepository->save($userProfile);
    }
}
