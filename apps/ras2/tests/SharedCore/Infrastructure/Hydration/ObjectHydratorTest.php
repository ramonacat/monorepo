<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\Hydration;

use DateTimeZone;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\DefaultHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ObjectHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ScalarHydrator;
use Ramona\Ras2\User\Application\Session;
use Ramona\Ras2\User\Business\UserId;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\Hydration\Mocks\WithUsername;

final class ObjectHydratorTest extends TestCase
{
    public function testPrefersInputValue(): void
    {
        $objectHydrator = new ObjectHydrator(WithUsername::class);
        $hydrator = new DefaultHydrator();
        $hydrator->installValueHydrator(new ScalarHydrator('string'));
        $hydrator->setSession(new Session(UserId::generate(), 'ramona', new DateTimeZone('Europe/Berlin')));

        $result = $objectHydrator->hydrate($hydrator, [
            'username' => 'not ramona',
        ], []);

        self::assertEquals('not ramona', $result?->username);
    }

    public function testCanUseSessionValue(): void
    {
        $objectHydrator = new ObjectHydrator(WithUsername::class);
        $hydrator = new DefaultHydrator();
        $hydrator->installValueHydrator(new ScalarHydrator('string'));
        $hydrator->setSession(new Session(UserId::generate(), 'ramona', new DateTimeZone('Europe/Berlin')));

        $result = $objectHydrator->hydrate($hydrator, [], []);

        self::assertEquals('ramona', $result?->username);
    }
}
