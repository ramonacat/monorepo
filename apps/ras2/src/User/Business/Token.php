<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Business;

use Random\Randomizer;
use Stringable;

final class Token implements Stringable
{
    public const TOKEN_LENGTH = 64;

    private function __construct(
        private string $value
    ) {
    }

    public function __toString()
    {
        return base64_encode($this->value);
    }

    public static function generate(\Random\Engine $randomEngine = null): self
    {
        $randomizer = new Randomizer($randomEngine);
        return new self($randomizer->getBytes(self::TOKEN_LENGTH));
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public static function fromString(string $raw): self
    {
        $raw = \Safe\base64_decode($raw, true);
        $tokenLength = strlen($raw);
        if ($tokenLength !== self::TOKEN_LENGTH) {
            throw InvalidTokenLength::for(expected: self::TOKEN_LENGTH, actual: $tokenLength);
        }

        return new self($raw);
    }
}
