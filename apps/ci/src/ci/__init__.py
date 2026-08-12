from argparse import ArgumentParser, Namespace
from datetime import UTC, datetime
from glob import glob
from os import makedirs
import os
from os.path import basename, realpath
import subprocess
from time import sleep
from typing import Callable, TypedDict, cast
import requests

from ci.cache import DirectoryCache
from ci.runtime_info import RuntimeInfo


class FailedRequest(BaseException):
    pass


class VersionStatus(TypedDict):
    version: int
    updated: bool


class RunCommandError(BaseException):
    pass


def run_command(command: list[str], silent: bool = True) -> None:
    print(f"running {command}")

    result = subprocess.run(command)

    if result.returncode != 0:
        raise RunCommandError(
            f"failed to run {command}",
            {"stdout": result.stdout, "stderr": result.stderr},
        )
    elif not silent:
        print(f"stdout:\n{result.stdout}\n")
        print(f"stderr:\n{result.stderr}\n")


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


def execute_setup(_args: Namespace, runtime: RuntimeInfo):
    required_dirs = ["/etc/nix", "~/.ssh", "~/.config/rclone"]
    for dir in required_dirs:
        makedirs(os.path.expanduser(dir), exist_ok=True)

    run_command(
        [
            "attic",
            "login",
            "https://attic.infrastructure.ramona.fun/",
            runtime.attic_token,
        ]
    )

    ssh_key_path = os.path.expanduser("~/.ssh/id_ed25519")
    descriptor = os.open(
        ssh_key_path, flags=os.O_WRONLY | os.O_CREAT | os.O_TRUNC, mode=0o600
    )
    with open(descriptor, "w") as file:
        _ = file.write(runtime.ssh_key)

    result = subprocess.run(["ssh-keygen", "-y", "-f", ssh_key_path])
    if result.returncode != 0:
        raise RunCommandError(
            "ssh-keygen", {"stdout": result.stdout, "stderr": result.stderr}
        )

    with open(os.path.expanduser("~/.ssh/id_ed25519.pub"), "w") as file:
        _ = file.write(str(result.stdout))

    run_command(
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
    run_command(
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
                        lambda: run_command(
                            [
                                "skopeo",
                                "copy",
                                f"docker-archive:{container_path}",
                                f"docker://{container_fullname}",
                            ]
                        )
                    )
        case "cache":
            cache_command = cast(str, args.cache_command)
            execute_cache_command(cache_command, args, runtime)
        case "setup":
            execute_setup(args, runtime)
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

    _ = subparsers.add_parser("setup")

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
