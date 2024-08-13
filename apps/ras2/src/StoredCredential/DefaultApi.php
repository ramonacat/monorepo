<?php

declare(strict_types=1);

namespace Ramona\Ras2\StoredCredential;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\User\Business\UserId;

final class DefaultApi implements Api
{
    public function __construct(
        private Connection $connection
    ) {
    }

    public function retrieve(string $name, UserId $owner): Credential
    {
        $raw = $this->connection->fetchAssociative('
            SELECT 
                id, name, owner, value 
            FROM credentials
            WHERE owner=:user_id AND name=:name
        ', [
            'user_id' => (string) $owner,
            'name' => $name,
        ]);

        if ($raw === false) {
            throw NotFound::forNameAndUser($name, $owner);
        }

        return new Credential(
            CredentialId::fromString($raw['id']),
            $raw['name'],
            UserId::fromString($raw['owner']),
            $raw['value']
        );
    }
}
