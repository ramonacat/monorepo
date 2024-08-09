<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ValueType;

final class WithArrayCollection
{
    /**
     * @var ArrayCollection<int, string>
     */
    #[Unrelated]
    #[KeyType('integer')]
    #[ValueType('string')]
    public ArrayCollection $things;
}
