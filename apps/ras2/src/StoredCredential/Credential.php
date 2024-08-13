<?php

declare(strict_types=1);

namespace Ramona\Ras2\StoredCredential;

use Ramona\Ras2\User\Business\UserId;

final class Credential
{
    public function __construct(
        private CredentialId $id,
        private string $name,
        private UserId $owner,
        #[\SensitiveParameter]
        private string $value
    ) {
    }

    /**
     * @return array<mixed>
     */
    public function __debugInfo(): ?array
    {
        return [
            'name' => $this->name,
            'owner' => $this->owner,
            'value' => '**CONFIDENTIAL**',
        ];
    }

    public function id(): CredentialId
    {
        return $this->id;
    }

    public function name(): string
    {
        return $this->name;
    }

    public function owner(): UserId
    {
        return $this->owner;
    }

    public function value(): string
    {
        return $this->value;
    }
}
