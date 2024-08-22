<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Psr\Http\Message\ResponseInterface;

interface JsonResponseFactory
{
    public function create(mixed $data): ResponseInterface;
}
