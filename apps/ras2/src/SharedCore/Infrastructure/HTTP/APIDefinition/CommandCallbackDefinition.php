<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition;

use Psr\Http\Message\ServerRequestInterface;

final class CommandCallbackDefinition
{
    /**
     * @param \Closure(ServerRequestInterface):?mixed $callback
     * @param class-string|'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL' $inputType
     * @param class-string|'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL' $responseType
     */
    public function __construct(
        public string $path,
        public string $commandName,
        public \Closure $callback,
        public string $inputType,
        public string $responseType
    ) {
    }
}
