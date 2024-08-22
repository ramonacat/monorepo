<?php

declare(strict_types=1);

namespace Ramona\Ras2\User;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Container;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\ContainerBuilder;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\CommandCallbackDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\CommandDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\EmptyQuery;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\QueryCallbackDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\QueryDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\DefaultHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\ObjectDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ObjectHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\Task\Application\Query\UserProfileByUserId;
use Ramona\Ras2\User\Application\Command\Login;
use Ramona\Ras2\User\Application\Command\LoginRequest;
use Ramona\Ras2\User\Application\Command\LoginResponse;
use Ramona\Ras2\User\Application\Command\UpsertUser;
use Ramona\Ras2\User\Application\Query\All;
use Ramona\Ras2\User\Application\Query\ByToken;
use Ramona\Ras2\User\Application\Session;
use Ramona\Ras2\User\Application\UserView;
use Ramona\Ras2\User\Business\Token;
use Ramona\Ras2\User\Infrastructure\CommandExecutor\LoginExecutor;
use Ramona\Ras2\User\Infrastructure\CommandExecutor\UpsertUserExecutor;
use Ramona\Ras2\User\Infrastructure\PostgresRepository;
use Ramona\Ras2\User\Infrastructure\QueryExecutor\AllExecutor;
use Ramona\Ras2\User\Infrastructure\QueryExecutor\ByTokenExecutor;
use Ramona\Ras2\User\Infrastructure\Repository;
use Ramona\Ras2\User\Infrastructure\TokenDehydrator;
use Ramona\Ras2\User\Infrastructure\UserIdDehydrator;
use Ramona\Ras2\User\Infrastructure\UserIdHydrator;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->register(
            Repository::class,
            fn (Container $c) => new PostgresRepository($c->get(Connection::class))
        );
    }

    public function register(Container $container): void
    {
        $hydrator = $container->get(DefaultHydrator::class);
        $hydrator->installValueHydrator(new ObjectHydrator(LoginRequest::class));
        $hydrator->installValueHydrator(new ObjectHydrator(UserView::class));
        $hydrator->installValueHydrator(new ObjectHydrator(All::class));
        $hydrator->installValueHydrator(new ObjectHydrator(UserProfileByUserId::class));
        $hydrator->installValueHydrator(new UserIdHydrator());

        $dehydrator = $container->get(Dehydrator::class);
        $dehydrator->installValueDehydrator(new UserIdDehydrator());
        $dehydrator->installValueDehydrator(new ObjectDehydrator(LoginResponse::class));
        $dehydrator->installValueDehydrator(new ObjectDehydrator(Session::class));
        $dehydrator->installValueDehydrator(new ObjectDehydrator(UserView::class));
        $dehydrator->installValueDehydrator(new TokenDehydrator());

        $commandBus = $container->get(CommandBus::class);
        $commandBus->installExecutor(UpsertUser::class, new UpsertUserExecutor($container->get(Repository::class)));
        $commandBus->installExecutor(Login::class, new LoginExecutor($container->get(Repository::class)));

        $queryBus = $container->get(QueryBus::class);
        $queryBus->installExecutor(ByToken::class, new ByTokenExecutor($container->get(Connection::class)));
        $queryBus->installExecutor(
            All::class,
            new AllExecutor($container->get(Connection::class), $container->get(DefaultHydrator::class))
        );

        /** @var APIDefinition $apiDefinition */
        $apiDefinition = $container->get(APIDefinition::class);
        $apiDefinition->installQueryCallback(
            new QueryCallbackDefinition('users', 'session', function (ServerRequestInterface $request) {
                return $request->getAttribute(RequireLogin::SESSION_ATTRIBUTE);
            }, EmptyQuery::class, Session::class)
        );
        $apiDefinition->installQuery(new QueryDefinition('users', 'all', All::class, ArrayCollection::class));
        $apiDefinition->installCommand(new CommandDefinition('users', 'upsert', UpsertUser::class));
        $apiDefinition->installCommandCallback(
            new CommandCallbackDefinition('users', 'login', function (ServerRequestInterface $request) use (
                $container
            ) {
                $request = $container->get(Deserializer::class)->deserialize(
                    LoginRequest::class,
                    $request->getBody()
                        ->getContents()
                );

                $token = Token::generate();

                $container->get(CommandBus::class)->execute(new Login($token, $request->username));

                return new LoginResponse($token);
            }, LoginRequest::class, LoginResponse::class)
        );
    }
}
