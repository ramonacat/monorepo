<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks\InvalidAnnotations;

use Doctrine\Common\Collections\ArrayCollection;

final class ArrayCollectionWithoutAttributes
{
    /**
     * @var ArrayCollection<int, string>
     */
    public ArrayCollection $things;
}
