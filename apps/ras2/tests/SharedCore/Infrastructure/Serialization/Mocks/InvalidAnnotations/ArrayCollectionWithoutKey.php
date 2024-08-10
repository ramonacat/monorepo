<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\InvalidAnnotations;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueType;

final class ArrayCollectionWithoutKey
{
    public function __construct(
        /**
         * @var ArrayCollection<int, int>
         */
        #[ValueType('integer')]
        public ArrayCollection $things
    ) {
    }
}
