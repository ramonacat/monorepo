<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure;

use PhpParser\Node;
use PhpParser\NodeTraverser;
use PhpParser\NodeVisitor\NameResolver;
use PhpParser\NodeVisitorAbstract;
use PhpParser\ParserFactory;
use Psr\SimpleCache\CacheInterface;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use RegexIterator;
use SplFileInfo;

final class ClassFinder
{
    public function __construct(
        private CacheInterface $cache
    ) {
    }

    /**
     * @return list<class-string>
     */
    public function findAllDeclaredClasses(): array
    {
        $files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator(__DIR__ . '/../../'));
        $files = new RegexIterator($files, '/\.php$/');

        $visitor = new class() extends NodeVisitorAbstract {
            /**
             * @var list<Node\Stmt\Class_>
             */
            public array $nodes = [];

            public function enterNode(Node $node)
            {
                if ($node instanceof Node\Stmt\Class_) {
                    $this->nodes[] = $node;
                }
                return parent::enterNode($node);
            }
        };
        $traverser = new NodeTraverser();
        $traverser->addVisitor(new NameResolver());
        $traverser->addVisitor($visitor);

        $parser = (new ParserFactory())->createForHostVersion();

        $result = [];

        foreach ($files as $file) {
            /** @var SplFileInfo $file */
            if (($cached = $this->cache->get(md5($file->getPathname()))) !== null) {
                if ($cached['mtime'] === $file->getMTime()) {
                    foreach ($cached['classes'] as $class_) {
                        $result[] = $class_;
                    }
                    continue;
                }
            }

            $stmts = $parser->parse(\Safe\file_get_contents($file->getPathname()));
            if ($stmts !== null) {
                $traverser->traverse($stmts);
            }

            $nodesFromCurrent = [];
            foreach ($visitor->nodes as $node) {
                if ($node->namespacedName !== null) {
                    $result[] = $node->namespacedName->toString();
                    $nodesFromCurrent[] = $node->namespacedName->toString();
                }
            }
            $this->cache->set(md5($file->getPathname()), [
                'classes' => $nodesFromCurrent,
                'mtime' => $file->getMTime(),
            ]);
            $visitor->nodes = [];
        }

        return $result;
    }
}
