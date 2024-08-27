<?php

declare(strict_types=1);

namespace Ramona\Ras2\User;

use DI\ContainerBuilder;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Psr\Container\ContainerInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\CommandCallbackDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\CommandDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\EmptyQuery;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\QueryCallbackDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\QueryDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\User\Application\Command\Login;
use Ramona\Ras2\User\Application\Command\LoginRequest;
use Ramona\Ras2\User\Application\Command\LoginResponse;
use Ramona\Ras2\User\Application\Command\UpsertUser;
use Ramona\Ras2\User\Application\Query\All;
use Ramona\Ras2\User\Application\Query\ByToken;
use Ramona\Ras2\User\Application\Session;
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
        $containerBuilder->addDefinitions([
            Repository::class => fn (ContainerInterface $c) => new PostgresRepository($c->get(Connection::class)),
        ]);
    }

    public function register(ContainerInterface $container): void
    {
        $hydrator = $container->get(Hydrator::class);
        $hydrator->installValueHydrator(new UserIdHydrator());

        $dehydrator = $container->get(Dehydrator::class);
        $dehydrator->installValueDehydrator(new UserIdDehydrator());
        $dehydrator->installValueDehydrator(new TokenDehydrator());

        $commandBus = $container->get(CommandBus::class);
        $commandBus->installExecutor(UpsertUser::class, new UpsertUserExecutor($container->get(Repository::class)));
        $commandBus->installExecutor(Login::class, new LoginExecutor($container->get(Repository::class)));

        $queryBus = $container->get(QueryBus::class);
        $queryBus->installExecutor(ByToken::class, new ByTokenExecutor($container->get(Connection::class)));
        $queryBus->installExecutor(
            All::class,
            new AllExecutor($container->get(Connection::class), $container->get(Hydrator::class))
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
