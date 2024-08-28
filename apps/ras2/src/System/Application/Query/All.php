<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Application\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIQuery;
use Ramona\Ras2\System\Application\SystemView;
use Ramona\Ras2\System\Infrastructure\QueryExecutor\AllExecutor;

/**
 * @implements Query<ArrayCollection<int, SystemView>>
 */
#[ExecutedBy(AllExecutor::class), APIQuery('systems', 'all')]
final class All implements Query
{
}
