<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;

use Ramona\Ras2\SharedCore\Business\Identifier;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueDehydrator;

/**
 * @implements ValueDehydrator<Identifier>
 */
final class IdentifierDehydrator implements ValueDehydrator
{
    /**
     * @param class-string<Identifier> $className
     */
    public function __construct(
        private string $className
    ) {

    }

    public function dehydrate(Dehydrator $dehydrator, mixed $value): string
    {
        return (string) $value;
    }

    /**
     * @return class-string<Identifier>
     */
    public function handles(): string
    {
        return $this->className;
    }
}
