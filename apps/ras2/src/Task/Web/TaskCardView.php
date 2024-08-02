<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Web;

use Ramona\Ras2\Task\Query\TaskSummary;

final class TaskCardView
{
    public function __construct(
        private TaskSummary $summary
    ) {
    }

    public function __toString()
    {
        $tags = implode(PHP_EOL, $this->summary->tags->map(fn (string $tag) => "<li>{$tag}</li>")->toArray());

        return <<<EOF
            ID: {$this->summary->id}, 
            state: {$this->summary->state},
            assignee: {$this->summary->assignee},
            title: {$this->summary->title}
            
            <ul>
                {$tags}
            </ul>
        EOF;

    }
}
