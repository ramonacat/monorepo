<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\User\Application\UserView;

/**
 * @implements Query<ArrayCollection<int, UserView>>
 */
final class All implements Query
{
}
