<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\User\UserId;
use Safe\DateTimeImmutable;

/**
 * @psalm-suppress UnusedClass
 */
class Done implements Task
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(
        private TaskDescription $description,
        private UserId $assignee
    ) {

    }

    public function id(): TaskId
    {
        return $this->description->id();
    }

    public function title(): string
    {
        return $this->description->title();
    }

    public function assigneeId(): ?UserId
    {
        return $this->assignee;
    }

    public function tags(): ArrayCollection
    {
        return $this->description->tags();
    }

    public function deadline(): ?DateTimeImmutable
    {
        return null; // TODO: should we keep it so we have history???
    }
}
