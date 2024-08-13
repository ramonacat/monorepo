<?php

declare(strict_types=1);

namespace Ramona\Ras2\StoredCredential;

use Ramona\Ras2\User\Business\UserId;

interface Api
{
    public function retrieve(string $name, UserId $owner): Credential;
}
