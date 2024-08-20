<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\System\Business;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\System\Business\NixOS;

final class NixOSTest extends TestCase
{
    public function testCanUpdateLatestClosure(): void
    {
        $nixos = new NixOS('/nix/store/blah', null);
        $nixos->updateLatestClosure('/nix/store/test');

        self::assertEquals('/nix/store/test', $nixos->latestClosure());
    }
}
