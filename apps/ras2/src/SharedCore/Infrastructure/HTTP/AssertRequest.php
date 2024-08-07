<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use League\Route\Http\Exception\NotAcceptableException;
use Psr\Http\Message\RequestInterface;

final class AssertRequest
{
    public static function isJson(RequestInterface $request): void
    {
        if ($request->getHeaderLine('Content-Type') !== 'application/json') {
            throw new NotAcceptableException();
        }
    }
}
