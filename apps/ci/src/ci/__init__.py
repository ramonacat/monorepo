from argparse import ArgumentParser, Namespace
from datetime import UTC, datetime
from glob import glob
from os.path import basename, realpath
from time import sleep
from typing import Callable, TypedDict, cast
import requests

from ci import containers
from ci.cache import DirectoryCache
from ci.runtime_info import RuntimeInfo


class FailedRequest(BaseException):
    pass


class VersionStatus(TypedDict):
    version: int
    updated: bool


def post_version(versioned_item: str, store_path: str) -> VersionStatus:
    response = requests.post(
        "https://ras.infrastructure.ramona.fun/versions",
        json={"versioned_item": versioned_item, "store_path": store_path},
    )

    if not response:
        raise FailedRequest(response)

    return cast(VersionStatus, response.json())


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


class CommandError(BaseException):
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


def execute_command(name: str, args: Namespace, runtime: RuntimeInfo) -> None:
    now_unix = (datetime.now(UTC) - datetime(1970, 1, 1, tzinfo=UTC)).total_seconds()

    match name:
        case "publish":
            print("starting publish")

            for container_path in glob("./result/containers/*"):
                container_name = basename(container_path)
                store_path = realpath(container_path)
                container_item_id = (
                    f"{runtime.repository_name}:containers:{container_name}"
                )

                print(f"found container {container_name} with store_path {store_path}")
                version_result = post_version(container_item_id, store_path)

                if version_result["updated"]:
                    print(f"container changed, publishing")

                    container_fullname = f"code.ramona.fun/ramona/{runtime.repository_name}/{container_name}:{now_unix}"
                    retry(
                        lambda: containers.upload_archive(
                            container_path, container_fullname
                        )
                    )
        case "cache":
            cache_command = cast(str, args.cache_command)
            execute_cache_command(cache_command, args, runtime)
        case _:
            raise CommandError(f"unknown command: {name}")


def main() -> None:
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

    args = parser.parse_args()
    command = cast(str, args.command)

    runtime = RuntimeInfo()

    print(f"running ci\n{runtime}")

    try:
        execute_command(command, args, runtime)
    except CommandError as e:
        print(e)

        parser.print_usage()
        exit(1)
