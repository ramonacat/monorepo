<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event;

use it\thecsea\simple_caldav_client\SimpleCalDAVClient;
use Laminas\Diactoros\Response;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\StoredCredential\Api;
use Ramona\Ras2\User\Application\Session;

final class GetEvents
{
    public function __construct(
        private Api $credentialApi
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        /** @var Session $session */
        $session = $request->getAttribute(RequireLogin::SESSION_ATTRIBUTE);
        $client = new SimpleCalDAVClient();
        $original = error_reporting(E_ERROR | E_WARNING);
        $client->connect(
            $this->credentialApi->retrieve('caldav-url', $session->userId)
                ->value(),
            $this->credentialApi->retrieve('caldav-username', $session->userId)
                ->value(),
            $this->credentialApi->retrieve('caldav-password', $session->userId)
                ->value(),
        );

        $calendars = $client->findCalendars();
        $client->setCalendar($calendars['F8EC7F14-41E0-11EF-AE19-561BB0C65FF4']);
        $events = $client->getEvents('20240801T000000Z', '20240820T000000Z');
        error_reporting($original);
        $response = new Response();
        $response->getBody()
            ->write((string) count($events));
        return $response;
    }
}
