<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command;

use Psr\Container\ContainerInterface;

final class DefaultCommandBus implements CommandBus
{
    /**
     * @var array<class-string<Command>, Executor<Command>>
     */
    private $executors = [];

    public function __construct(
        private ContainerInterface $container
    ) {
    }

    public function installExecutor(string $type, object $handler): void
    {
        $this->executors[$type] = $handler;
    }

    public function execute(Command $command): void
    {
        $executor = $this->executors[get_class($command)] ?? null;

        if ($executor === null) {
            $reflectionClass = new \ReflectionClass($command);
            foreach ($reflectionClass->getAttributes() as $attribute) {
                if ($attribute->getName() === ExecutedBy::class) {
                    /** @var ExecutedBy $attributeInstance */
                    $attributeInstance = $attribute->newInstance();
                    $executor = $this->container->get($attributeInstance->class);
                }
            }
        }

        if ($executor === null) {
            throw NoExecutor::forCommand($command);
        }

        $executor->execute($command);
    }
}
