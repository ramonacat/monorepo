<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application;

enum Status
{
    case BACKLOG_ITEM;
    case IDEA;
    case STARTED;
    case DONE;
}
