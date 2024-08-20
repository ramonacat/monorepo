<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Event\Event\Appplication\HttpApi;

use Doctrine\Common\Collections\ArrayCollection;
use Laminas\Diactoros\ServerRequest;
use Ramona\Ras2\Event\Application\EventView;
use Ramona\Ras2\Event\Application\HttpApi\GetEvents;
use Ramona\Ras2\Event\Application\Query\InMonth;
use Ramona\Ras2\Event\Business\EventId;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;
use Tests\Ramona\Ras2\EndpointCase;

final class GetEventsTest extends EndpointCase
{
    public function testCanGetEvents(): void
    {
        $queryBus = new QueryBus();
        $mockExecutor = new MockInMonthExecutor(new ArrayCollection([
            new EventView(
                EventId::fromString('019154ca-d3e1-72bb-b395-cd222d62acdc'),
                'test',
                new \Safe\DateTimeImmutable('2020-02-02 02:02:02'),
                new \Safe\DateTimeImmutable('2020-02-02 02:02:02'),
                new ArrayCollection(['ramona'])
            ),
        ]));
        $queryBus->installExecutor(InMonth::class, $mockExecutor);

        $controller = new GetEvents($queryBus, $this->container->get(JsonResponseFactory::class));

        $request = new ServerRequest(
            queryParams: [
                'year' => '2024',
                'month' => '8',
            ]
        );

        $response = ($controller)($request);
        $response->getBody()
            ->seek(0);

        self::assertJsonStringEqualsJsonString('[{
            "attendeeUsernames": ["ramona"],
            "id": "019154ca-d3e1-72bb-b395-cd222d62acdc",
            "title": "test",
            "start": {
                "timestamp": "2020-02-02 02:02:02",
                "timezone": "UTC"
            },
            "end": {
                "timestamp": "2020-02-02 02:02:02",
                "timezone": "UTC"
            }
        }]', $response->getBody()->getContents());
    }
}
