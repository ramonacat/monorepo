<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use DI\ContainerBuilder;
use Doctrine\DBAL\Connection;
use Psr\Container\ContainerInterface;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\CommandDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\QueryDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Application\Command\FinishWork;
use Ramona\Ras2\Task\Application\Command\PauseWork;
use Ramona\Ras2\Task\Application\Command\ReturnToBacklog;
use Ramona\Ras2\Task\Application\Command\ReturnToIdea;
use Ramona\Ras2\Task\Application\Command\StartWork;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;
use Ramona\Ras2\Task\Application\Command\UpsertUserProfile;
use Ramona\Ras2\Task\Application\Query\ById;
use Ramona\Ras2\Task\Application\Query\Current;
use Ramona\Ras2\Task\Application\Query\Ideas;
use Ramona\Ras2\Task\Application\Query\Upcoming;
use Ramona\Ras2\Task\Application\Query\UserProfileByUserId;
use Ramona\Ras2\Task\Application\Query\WatchedBy;
use Ramona\Ras2\Task\Infrastructure\PostgresRepository;
use Ramona\Ras2\Task\Infrastructure\PostgresUserProfileRepository;
use Ramona\Ras2\Task\Infrastructure\Repository;
use Ramona\Ras2\Task\Infrastructure\UserProfileRepository;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->addDefinitions([
            Repository::class => fn (ContainerInterface $c) => new PostgresRepository(
                $c->get(Connection::class),
                $c->get(Serializer::class),
                $c->get(Deserializer::class)
            ),
            UserProfileRepository::class => fn (ContainerInterface $c) => new PostgresUserProfileRepository(
                $c->get(Connection::class),
                $c->get(Serializer::class)
            ),
        ]);
    }

    public function register(ContainerInterface $container): void
    {
        /** @var APIDefinition $apiDefinition */
        $apiDefinition = $container->get(APIDefinition::class);
        $apiDefinition->installQuery(new QueryDefinition('tasks', 'upcoming', Upcoming::class));
        $apiDefinition->installQuery(new QueryDefinition('tasks', 'watched', WatchedBy::class));
        $apiDefinition->installQuery(new QueryDefinition('tasks', 'ideas', Ideas::class));
        $apiDefinition->installQuery(new QueryDefinition('tasks', 'current', Current::class));
        $apiDefinition->installQuery(new QueryDefinition('tasks/{id:uuid}', 'by-id', ById::class));
        $apiDefinition->installQuery(
            new QueryDefinition('tasks/user-profiles', 'current', UserProfileByUserId::class)
        );
        $apiDefinition->installCommand(new CommandDefinition('tasks', 'upsert:idea', UpsertIdea::class));
        $apiDefinition->installCommand(
            new CommandDefinition('tasks', 'upsert:backlog-item', UpsertBacklogItem::class)
        );
        $apiDefinition->installCommand(new CommandDefinition('tasks', 'start-work', StartWork::class));
        $apiDefinition->installCommand(new CommandDefinition('tasks', 'pause-work', PauseWork::class));
        $apiDefinition->installCommand(new CommandDefinition('tasks', 'finish-work', FinishWork::class));
        $apiDefinition->installCommand(new CommandDefinition('tasks', 'return-to-backlog', ReturnToBacklog::class));
        $apiDefinition->installCommand(new CommandDefinition('tasks', 'return-to-idea', ReturnToIdea::class));
        $apiDefinition->installCommand(
            new CommandDefinition('tasks/user-profiles', 'upsert', UpsertUserProfile::class)
        );
    }
}
