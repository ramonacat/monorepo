<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Event\Appplication\HttpApi;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\Event\Application\EventView;
use Ramona\Ras2\Event\Application\Query\InMonth;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;

/**
 * @implements Executor<ArrayCollection<int, EventView>, InMonth>
 */
final class MockInMonthExecutor implements Executor
{
    public ?InMonth $query = null;

    /**
     * @param ArrayCollection<int, EventView> $result
     */
    public function __construct(
        private readonly ArrayCollection $result
    ) {
    }

    public function execute(Query $query): mixed
    {
        $this->query = $query;

        return $this->result;
    }
}
