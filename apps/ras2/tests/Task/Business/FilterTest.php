<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Business;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\Business\Filter;
use Ramona\Ras2\Task\Business\FilterId;
use Ramona\Ras2\Task\Business\TagId;
use Ramona\Ras2\User\Business\UserId;

final class FilterTest extends TestCase
{
    public function testHasAnId(): void
    {
        $id = FilterId::generate();
        $filter = new Filter($id, 'name', new ArrayCollection([]), new ArrayCollection([]));

        self::assertEquals($id, $filter->id());
    }

    public function testHasAName(): void
    {
        $id = FilterId::generate();
        $filter = new Filter($id, 'name', new ArrayCollection([]), new ArrayCollection([]));

        self::assertEquals('name', $filter->name());
    }

    public function testHasAssignees(): void
    {
        $userA = UserId::generate();
        $userB = UserId::generate();
        $filter = new Filter(
            FilterId::generate(),
            'name',
            new ArrayCollection([$userA, $userB]),
            new ArrayCollection([])
        );

        self::assertEquals(new ArrayCollection([$userA, $userB]), $filter->assignees());
    }

    public function testHasTags(): void
    {
        $tagA = TagId::generate();
        $tagB = TagId::generate();

        $filter = new Filter(
            FilterId::generate(),
            'name',
            new ArrayCollection([]),
            new ArrayCollection([$tagA, $tagB])
        );

        self::assertEquals(new ArrayCollection([$tagA, $tagB]), $filter->tags());
    }
}
