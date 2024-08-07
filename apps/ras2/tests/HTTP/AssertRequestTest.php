<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\HTTP;

use Laminas\Diactoros\Request;
use League\Route\Http\Exception\NotAcceptableException;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\HTTP\AssertRequest;

final class AssertRequestTest extends TestCase
{
    public function testThrowsIfContentTypeIsNotJson(): void
    {
        $request = new Request(headers: [
            'Content-Type' => 'text/plain',
        ]);

        $this->expectException(NotAcceptableException::class);
        AssertRequest::isJson($request);
    }
}
