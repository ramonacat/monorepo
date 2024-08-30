<?php

declare(strict_types=1);

namespace System\Business;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\System\Business\SystemId;

final class SystemIdTest extends TestCase
{
    public function testCanBeCreatedFromString(): void
    {
        $systemId = SystemId::fromString('0191a41e-16ba-7cf1-b9db-7579266e22f2');

        self::assertEquals('0191a41e-16ba-7cf1-b9db-7579266e22f2', (string) $systemId);
    }
}
