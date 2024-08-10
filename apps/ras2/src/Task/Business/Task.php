<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\User\Business\UserId;
use Safe\DateTimeImmutable;

interface Task
{
    public function id(): TaskId;

    public function title(): string;

    public function assigneeId(): ?UserId;

    /**
     * @return ArrayCollection<int, TagId>
     */
    public function tags(): ArrayCollection;

    public function deadline(): ?DateTimeImmutable;
}
