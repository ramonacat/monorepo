<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Web;

final class RootView
{
    public function __construct(
        private string $body
    ) {
    }

    public function __toString(): string
    {
        return <<<EOF
        <!DOCTYPE html>
        <html lang='en'>
            <head>
                <title>Ramona's Service</title>
                <script async src="/assets/main.js"></script>
                <link rel="stylesheet" href="/assets/main.css" />
            </head>
            <body>
                {$this->body}
            </body>
        </html>
        EOF;
    }
}
