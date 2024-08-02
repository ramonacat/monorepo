<?php

declare(strict_types=1);

require_once __DIR__ . '/../vendor/autoload.php';

/** @var list<string> $modules */
$modules = \Safe\glob(__DIR__ . '/../src-frontend/css/**.css.json');

foreach ($modules as $modulePath) {
    $moduleName = str_replace('.css.json', '', basename($modulePath));

    $moduleFile = new Nette\PhpGenerator\PhpFile();
    $moduleFile->addNamespace('Generated\Ramona\Ras2\CSSModules');

    $className = ucfirst($moduleName);
    $moduleClass = $moduleFile
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

    @\Safe\mkdir(__DIR__ . '/../src-generated/CSSModules/', recursive: true);
    \Safe\file_put_contents(__DIR__ . '/../src-generated/CSSModules/' . $className . '.php', $generatedCode);
}
