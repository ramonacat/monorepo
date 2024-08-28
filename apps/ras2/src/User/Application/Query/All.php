<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIQuery;
use Ramona\Ras2\User\Application\UserView;
use Ramona\Ras2\User\Infrastructure\QueryExecutor\AllExecutor;

/**
 * @implements Query<ArrayCollection<int, UserView>>
 */
#[ExecutedBy(AllExecutor::class), APIQuery('users', 'all')]
final class All implements Query
{
}
