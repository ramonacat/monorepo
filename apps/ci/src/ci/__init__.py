from argparse import ArgumentParser, Namespace
from contextlib import chdir
from datetime import UTC, datetime
from glob import glob
import logging
import os
from os.path import basename, realpath
from pathlib import Path
import re
import sys
from time import sleep
from typing import Callable, TypedDict, cast
import requests

from ci.app import find_roots
from ci.cache import DirectoryCache
from ci.checks import run_checks
from ci.commands import run_command
from ci.runtime_info import RuntimeInfo

logger = logging.getLogger(__name__)


class FailedRequest(Exception):
    pass


class VersionStatus(TypedDict):
    version: int
    updated: bool


def api_post(url: str, json: object) -> object:
    response = requests.post(url, json=json)

    if not response:
        raise FailedRequest(
            f"request to {url} failed with status {response.status_code}, response body:\n{response.text}"
        )

    return cast(object, response.json())


def post_version(versioned_item: str, store_path: str) -> VersionStatus:
    return cast(
        VersionStatus,
        api_post(
            "https://ras.infrastructure.ramona.fun/versions",
            json={"versioned_item": versioned_item, "store_path": store_path},
        ),
    )


def retry[T](callback: Callable[[], T]) -> T:
    i: int = 0
    while True:
        try:
            return callback()
        except Exception as e:
            if i == 5:
                raise Exception("retries exhausted", e)
            i += 1
            sleep(cast(int, 2**i))


class CommandError(Exception):
    pass


def execute_cache_command(name: str, args: Namespace, runtime: RuntimeInfo):
    directory_cache = DirectoryCache(runtime)

    match name:
        case "pull":
            directory_cache.pull(cast(str, args.key))
        case "push":
            directory_cache.push(cast(str, args.key), cast(str, args.path))
        case _:
            raise CommandError(f"unknown cache command: {name}")


def execute_setup(_args: Namespace, runtime: RuntimeInfo):
    _ = run_command(
        [
            "attic",
            "login",
            "main",
            "https://attic.infrastructure.ramona.fun/",
            runtime.attic_token,
        ]
    )
    _ = run_command(["attic", "use", "main"])

    ssh_key_path = os.path.expanduser("~/.ssh/id_ed25519")
    descriptor = os.open(
        ssh_key_path, flags=os.O_WRONLY | os.O_CREAT | os.O_TRUNC, mode=0o600
    )

    with open(descriptor, "w+b") as file:
        _ = file.write(runtime.ssh_key.encode("utf-8"))
        _ = file.write(b"\n")

    public_key = run_command(["ssh-keygen", "-y", "-f", ssh_key_path])

    with open(os.path.expanduser("~/.ssh/id_ed25519.pub"), "w") as file:
        _ = file.write(str(public_key))

    _ = run_command(
        [
            "skopeo",
            "login",
            "--username",
            "ramonacat",
            "--password",
            runtime.github_token,
            "ghcr.io",
        ]
    )
    _ = run_command(
        [
            "skopeo",
            "login",
            "--username",
            "ramona",
            "--password",
            runtime.forgejo_token,
            "code.ramona.fun",
        ]
    )

    with open(os.path.expanduser("~/.npmrc"), "wb") as file:
        _ = file.write(
            f"//npm.pkg.github.com/:_authToken={runtime.github_token}\n".encode("utf-8")
        )
        _ = file.write(
            f"//code.ramona.fun/api/packages/ramona/npm/:_authToken={runtime.forgejo_token}\n".encode(
                "utf-8"
            )
        )


def execute_command(name: str, args: Namespace, runtime: RuntimeInfo) -> None:
    now_unix = (datetime.now(UTC) - datetime(1970, 1, 1, tzinfo=UTC)).total_seconds()

    match name:
        case "publish":
            logger.info("starting publish")

            for container_path in glob("./result/containers/*"):
                container_name = basename(container_path)
                store_path = realpath(container_path)
                container_item_id = (
                    f"{runtime.repository_name}:containers:{container_name}"
                )

                logger.info(
                    f"found container {container_name} with store_path {store_path}"
                )
                version_result = post_version(container_item_id, store_path)

                if version_result["updated"]:
                    logger.info(f"container changed, publishing")

                    container_fullname = f"code.ramona.fun/ramona/{runtime.repository_name}/{container_name}:{now_unix}"
                    _ = retry(
                        lambda: run_command(
                            [
                                "skopeo",
                                "copy",
                                f"docker-archive:{container_path}",
                                f"docker://{container_fullname}",
                            ]
                        )
                    )

            for npm_path in glob("./result/npm-packages/*"):
                with chdir(npm_path):
                    npm_name = basename(npm_path)
                    store_path = realpath(npm_path)
                    version_result = post_version(
                        f"{runtime.repository_name}:npm-packages:{npm_name}", store_path
                    )

                    # TODO also add a check on PRs to ensure version is bumped
                    if version_result["updated"]:
                        _ = run_command(["npm", "publish"])

            for iso_path in glob("./result/iso/**"):
                iso_name = basename(iso_path)
                container_item_id = f"{runtime.repository_name}:isos:{iso_name}"
                store_path = realpath(iso_path)
                version_result = post_version(container_item_id, store_path)

                logger.info(f"found iso {name} with store path {store_path}")

                if version_result["updated"]:
                    logger.info("iso changed, publishing")

                    with open(next(Path(store_path).rglob("*.iso")), "rb") as file:
                        runtime.cache_client.upload_fileobj(
                            file,
                            runtime.public_bucket,
                            f"isos/{re.sub("^(nixos-.*?)-\\d.*", "\\1", iso_name)}.iso",
                        )
            for closure_path in glob("./result/hosts/*"):
                home_name = basename(closure_path)
                store_path = realpath(closure_path)

                logger.info(
                    f"found nixos configuration {home_name} with store path {store_path}"
                )

                # TODO also do nix-store closure-diff and post the results as a comment on the PR
                _ = api_post(
                    f"https://ras.infrastructure.ramona.fun/hosts/{home_name}/latest_closure",
                    json={"latest_closure": store_path},
                )

            for home_path in glob("./result/homes/*"):
                home_name = basename(home_path)
                store_path = realpath(home_path)

                logger.info(
                    f"found home-manager configuration {home_name} with store path {store_path}"
                )

                # TODO do a diff and post as PR comment
                _ = api_post(
                    f"https://ras.infrastructure.ramona.fun/homes/{home_name}/latest_closure",
                    json={"latest_closure": store_path},
                )

        case "cache":
            cache_command = cast(str, args.cache_command)
            execute_cache_command(cache_command, args, runtime)
        case "setup":
            execute_setup(args, runtime)
        case "check":
            repository_root = Path(
                run_command(["git", "rev-parse", "--show-toplevel"]).rstrip()
            )

            app_roots = find_roots(repository_root)
            run_checks(app_roots)
        case unknown:
            raise CommandError(f"unknown command: '{unknown}'")


def main() -> None:
    logging.basicConfig(stream=sys.stderr, level="INFO")

    logging.info("ci command initializing")

    parser = ArgumentParser(description="ci")

    subparsers = parser.add_subparsers(dest="command", help="command", required=True)

    _ = subparsers.add_parser("publish")

    parser_cache = subparsers.add_parser("cache")
    subparsers_cache = parser_cache.add_subparsers(
        dest="cache_command", help="cache command", required=True
    )
    parser_cache_pull = subparsers_cache.add_parser("pull")
    _ = parser_cache_pull.add_argument("key", help="cache key")

    parser_cache_push = subparsers_cache.add_parser("push")
    _ = parser_cache_push.add_argument("key", help="cache key")
    _ = parser_cache_push.add_argument("path", help="path to cache")

    _ = subparsers.add_parser("setup")
    _ = subparsers.add_parser("check")

    args = parser.parse_args()
    command = cast(str, args.command)

    runtime = RuntimeInfo()

    logger.info(f"ci with runtime information:\n{runtime}\n")

    try:
        execute_command(command, args, runtime)
    except CommandError as e:
        logger.error(e)

        parser.print_usage()
        exit(1)
