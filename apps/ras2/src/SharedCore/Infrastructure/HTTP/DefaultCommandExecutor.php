<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Laminas\Diactoros\Response\EmptyResponse;
use League\Route\Http\Exception\BadRequestException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;

final class DefaultCommandExecutor implements CommandExecutor
{
    public function __construct(
        private Deserializer $deserializer,
        private CommandBus $commandBus
    ) {
    }

    /**
     * @param array<string, class-string<Command>> $actionToCommandType
     */
    public function execute(ServerRequestInterface $request, array $actionToCommandType): ResponseInterface
    {
        AssertRequest::isJson($request);
        $commandType = $actionToCommandType[$request->getHeaderLine('X-Action')] ?? null;

        if ($commandType === null) {
            throw new BadRequestException();
        }

        $command = $this->deserializer->deserialize($commandType, $request->getBody()->getContents());
        $this->commandBus->execute($command);

        return new EmptyResponse();
    }
}
