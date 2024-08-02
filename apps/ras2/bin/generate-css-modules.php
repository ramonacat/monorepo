<?php

declare(strict_types=1);

use Safe\Exceptions\FilesystemException;

require_once __DIR__ . '/../vendor/autoload.php';

/** @var list<string> $modules */
$modules = \Safe\glob(__DIR__ . '/../src-frontend/css/**.css.json');

foreach ($modules as $modulePath) {
    $moduleName = str_replace('.css.json', '', basename($modulePath));

    $moduleFile = new Nette\PhpGenerator\PhpFile();
    $namespace = $moduleFile->addNamespace('Generated\\Ramona\\Ras2\\CSSModules');

    $className = ucfirst($moduleName);
    $moduleClass = $namespace
        ->addClass($className);

    /** @var array<string, string> $parsedMapping */
    $parsedMapping = \Safe\json_decode(\Safe\file_get_contents($modulePath));

    foreach ($parsedMapping as $original => $mapped) {
        $moduleClass
            ->addMethod($original)
            ->setPublic()
            ->setStatic()
            ->setReturnType('string')
            ->addBody('return ?;', [$mapped]);
    }

    $generatedCode = (string) $moduleFile;

    try {
        @\Safe\mkdir(__DIR__ . '/../src-generated/CSSModules/', recursive: true);
    } catch (FilesystemException $e) {
        if (! str_contains($e->getMessage(), 'File exists')) {
            throw $e;
        }
    }
    \Safe\file_put_contents(__DIR__ . '/../src-generated/CSSModules/' . $className . '.php', $generatedCode);
}
