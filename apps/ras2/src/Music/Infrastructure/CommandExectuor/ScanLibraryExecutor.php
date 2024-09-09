<?php

declare(strict_types=1);

namespace Ramona\Ras2\Music\Infrastructure\CommandExectuor;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use getID3;
use Ramona\Ras2\Music\Application\Command\ScanLibrary;
use Ramona\Ras2\Music\Business\AlbumId;
use Ramona\Ras2\Music\Business\ArtistId;
use Ramona\Ras2\Music\Business\LibraryId;
use Ramona\Ras2\Music\Business\TrackId;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use RuntimeException;
use SplFileInfo;

/**
 * @implements Executor<ScanLibrary>
 */
final class ScanLibraryExecutor implements Executor
{
    public function __construct(
        private Connection $connection
    ) {
    }

    public function execute(Command $command): void
    {
        $path = $this->connection->fetchOne('SELECT path FROM music_libraries WHERE id=:id', [
            'id' => $command->id,
        ]);
        if ($path === false) {
            throw new RuntimeException('Library not found');
        }

        $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($path));
        $getId3 = new getID3();

        $tracks = [];

        $i = 0;
        foreach ($iterator as $file) {
            /** @var SplFileInfo $file */
            if (
                ! $file->isFile()
                || $file->getExtension() !== 'flac'
            ) {
                continue;
            }

            $tags = $getId3->analyze($file->getPathname());
            $tags = $tags['tags']['vorbiscomment'] ?? null;

            if ($tags === null) {
                throw new RuntimeException('No tags found for: ' . $file->getPathname());
            }

            $tracks[str_replace($path, '', $file->getPathname())] = [
                'id' => TrackId::generate(),
                'album_artist' => $tags['albumartist'][0] ?? $tags['artist'][0],
                'artist' => $tags['artist'][0],
                'album' => $tags['album'][0],
                'title' => $tags['title'][0],
                'track_number' => explode('/', $tags['tracknumber'][0])[0],
                'disc_number' => explode('/', $tags['discnumber'][0] ?? '1')[0],
            ];
        }

        $tracks = new ArrayCollection($tracks);
        $this->connection->transactional(function () use ($command, $tracks) {
            $this->connection->executeStatement(
                'DELETE FROM music_track WHERE path NOT IN(SELECT value from json_array_elements_text(:paths))',
                [
                    'paths' => \Safe\json_encode($tracks->getKeys()),
                ]
            );

            $all = $this->connection->fetchAllAssociative(
                'SELECT id, path FROM music_track WHERE path IN(SELECT value from json_array_elements_text(:paths))',
                [
                    'paths' => \Safe\json_encode($tracks->getKeys()),
                ]
            );

            foreach ($all as $track) {
                if (isset($tracks[$track['path']])) {
                    $tracks[$track['path']]['id'] = TrackId::fromString($track['id']);
                }
            }

            foreach ($tracks as $path => $track) {
                $artistId = $this->fetchOrCreateArtistId($track['album_artist']);
                $albumId = $this->fetchOrCreateAlbumId($command->id, $artistId, $track['album']);

                $this->connection->executeStatement('
                    INSERT INTO music_track(id, album_id, title, path, track_number, disc_number) 
                    VALUES (:id, :album_id, :title, :path, :track_number, :disc_number)
                    ON CONFLICT(id) DO UPDATE 
                        SET album_id=:album_id, title=:title, path=:path, track_number=:track_number, disc_number=:disc_number
                ', [
                    'id' => (string) $track['id'],
                    'album_id' => (string) $albumId,
                    'title' => $track['title'],
                    'path' => $path,
                    'track_number' => $track['track_number'],
                    'disc_number' => $track['disc_number'],
                ]);
            }
        });
    }

    private function fetchOrCreateArtistId(string $name): ArtistId
    {
        $result = $this->connection->fetchOne('SELECT id FROM music_artist WHERE name=:name', [
            'name' => $name,
        ]);

        if ($result === false) {
            $id = ArtistId::generate();
            $this->connection->executeStatement(
                'INSERT INTO music_artist(id, name) VALUES (:id, :name)',
                [
                    'id' => (string) $id,
                    'name' => $name,
                ]
            );
            return $id;
        }

        return ArtistId::fromString($result);
    }

    private function fetchOrCreateAlbumId(LibraryId $libraryId, ArtistId $artistId, string $title): AlbumId
    {
        $result = $this->connection->fetchOne(
            'SELECT id FROM music_album WHERE library_id=:library_id AND artist_id=:artist_id AND title=:title',
            [
                'library_id' => (string) $libraryId,
                'artist_id' => (string) $artistId,
                'title' => $title,
            ]
        );

        if ($result === false) {
            $id = AlbumId::generate();
            $this->connection->executeStatement(
                'INSERT INTO music_album(id, library_id, artist_id, title) VALUES (:id, :library_id, :artist_id, :title)',
                [
                    'id' => (string) $id,
                    'library_id' => (string) $libraryId,
                    'artist_id' => (string) $artistId,
                    'title' => $title,
                ]
            );

            return $id;
        }

        return AlbumId::fromString($result);
    }
}
