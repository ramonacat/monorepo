<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use League\Route\Http\Exception\MethodNotAllowedException;
use League\Route\Http\Exception\NotFoundException;
use League\Route\Route;
use League\Route\Strategy\StrategyInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;

final class RouteStrategy implements StrategyInterface
{
    public function __construct(
        private StrategyInterface $inner,
        private LogExceptions $logExceptions
    ) {
    }

    public function addResponseDecorator(callable $decorator): StrategyInterface
    {
        return $this->inner->addResponseDecorator($decorator);
    }

    public function getMethodNotAllowedDecorator(MethodNotAllowedException $exception): MiddlewareInterface
    {
        return $this->inner->getMethodNotAllowedDecorator($exception);
    }

    public function getNotFoundDecorator(NotFoundException $exception): MiddlewareInterface
    {
        return $this->inner->getNotFoundDecorator($exception);
    }

    public function getThrowableHandler(): MiddlewareInterface
    {
        return $this->logExceptions;
    }

    public function invokeRouteCallable(Route $route, ServerRequestInterface $request): ResponseInterface
    {
        return $this->inner->invokeRouteCallable($route, $request);
    }
}
