from argparse import ArgumentParser, Namespace
import json
import logging
import os
from os.path import basename, realpath
from pathlib import Path
import sys
from typing import cast

from ci.app import find_roots
from ci.cache import DirectoryCache
from ci.checks import run_checks
from ci.commands import run_command
from ci.publish import execute_publish
from ci.ras_client import VersionedItemId, check_version
from ci.runtime_info import RuntimeInfo

logger = logging.getLogger(__name__)


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

    with open(os.path.expanduser("~/.netrc"), "wb") as file:
        _ = file.write(
            f"machine code.ramona.fun login ramona password {runtime.forgejo_token}".encode(
                "utf-8"
            )
        )


def execute_validate_built(runtime: RuntimeInfo):
    for npm_package in Path("./result/npm-packages").glob("*"):
        app_name = basename(npm_package)
        store_path = realpath(npm_package)

        if runtime.pull_request != None:
            version_status = check_version(
                VersionedItemId.npm_package(app_name, runtime), store_path
            )
            if not version_status["updated"]:
                return

            # TODO how do we handle apps? do we even need to?
            package_json_path = Path("libs/js") / app_name / "package.json"

            _ = run_command(["git", "fetch"])
            base_package_json = cast(
                dict[str, object],
                json.loads(
                    run_command(
                        [
                            "git",
                            "show",
                            f"origin/{runtime.pull_request.base}:{package_json_path}",
                        ]
                    )
                ),
            )
            with open(package_json_path, "rb") as package_json_file:
                package_json = cast(dict[str, object], json.load(package_json_file))

            if base_package_json["version"] == package_json["version"]:
                raise Exception(
                    f"npm package {app_name} has changed, but version field was not updated"
                )


def execute_command(name: str, args: Namespace, runtime: RuntimeInfo) -> None:
    match name:
        case "publish":
            execute_publish(runtime)
        case "cache":
            cache_command = cast(str, args.cache_command)
            execute_cache_command(cache_command, args, runtime)
        case "setup":
            execute_setup(args, runtime)
        case "check":
            app_roots = find_roots(runtime.repository.root)
            run_checks(app_roots)
        case "validate-built":
            execute_validate_built(runtime)
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
    _ = subparsers.add_parser("validate-built")

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
