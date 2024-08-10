<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\User\Business\UserId;
use Safe\DateTimeImmutable;

final class Started implements Task
{
    public function __construct(
        private TaskDescription $description,
        private UserId $assignee,
        private ?DateTimeImmutable $deadline
    ) {
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function description(): TaskDescription
    {
        return $this->description;
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function assigneeId(): UserId
    {
        return $this->assignee;
    }

    public function id(): TaskId
    {
        return $this->description->id();
    }

    public function title(): string
    {
        return $this->description->title();
    }

    public function tags(): ArrayCollection
    {
        return $this->description->tags();
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function deadline(): ?DateTimeImmutable
    {
        return $this->deadline;
    }
}
