<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Application\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\System\Application\SystemView;

/**
 * @implements Query<ArrayCollection<int, SystemView>>
 */
final class All implements Query
{
}
