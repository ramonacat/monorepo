from argparse import ArgumentParser
from datetime import UTC, datetime
from glob import glob
from os.path import basename, realpath
import subprocess
from time import sleep
from typing import TypedDict, cast
import requests


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


def main() -> None:
    parser = ArgumentParser(description="ci")
    _ = parser.add_argument("repository")

    subparsers = parser.add_subparsers(dest="subparser_name", help="command")
    _parser_publish = subparsers.add_parser("publish")

    args = parser.parse_args()
    subparser_name = cast(str, args.subparser_name)
    repository_name = cast(str, args.repository)

    now_unix = (datetime.now(UTC) - datetime(1970, 1, 1, tzinfo=UTC)).total_seconds()

    print(f"running ci in repository {repository_name}")

    match subparser_name:
        case "publish":
            print("starting publish")

            for container_path in glob("./result/containers/*"):
                container_name = basename(container_path)
                store_path = realpath(container_path)
                container_item_id = f"{repository_name}:containers:{container_name}"

                print(f"found container {container_name} with store_path {store_path}")
                version_result = post_version(container_item_id, store_path)

                if version_result["updated"]:
                    print(f"container changed, publishing")
                    container_fullname = f"code.ramona.fun/ramona/{repository_name}/{container_name}:{now_unix}"

                    for i in range(0, 5):
                        result = subprocess.run(
                            [
                                "skopeo",
                                "copy",
                                f"docker-archive:$container_path",
                                f"docker://{container_fullname}",
                            ]
                        )

                        if result.returncode == 0:
                            break
                        else:
                            sleep(2**i)
        case _:
            parser.print_help()

            exit(1)
