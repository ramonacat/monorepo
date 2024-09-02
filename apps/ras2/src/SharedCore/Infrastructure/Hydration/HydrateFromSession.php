<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

use Attribute;
use Ramona\Ras2\User\Application\Session;

#[Attribute(Attribute::TARGET_PROPERTY)]
final readonly class HydrateFromSession implements HydrationAttribute
{
    public function __construct(
        public string $fieldName
    ) {
        assert(property_exists(Session::class, $fieldName));
    }
}
