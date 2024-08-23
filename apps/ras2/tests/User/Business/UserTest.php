<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\User\Business;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\User\Business\User;
use Ramona\Ras2\User\Business\UserId;
use Ramona\Ras2\User\Business\UsernameTooShort;

final class UserTest extends TestCase
{
    public function testThrowsOnTooShortUsername(): void
    {
        $this->expectException(UsernameTooShort::class);

        new User(UserId::generate(), 'ra', true, new \DateTimeZone('Europe/Berlin'));
    }

    public function testCanCreateWithThreeLetterUsername(): void
    {
        $user = new User(UserId::generate(), 'rad', true, new \DateTimeZone('Europe/Berlin'));

        self::assertEquals('rad', $user->name());
    }
}
