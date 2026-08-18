from contextlib import chdir
from glob import glob
import logging
from os.path import basename, realpath
from pathlib import Path
import re

from ci.commands import retry, run_command
from ci.ras_client import VersionedItemId, api_post, update_version
from ci.runtime_info import RuntimeInfo

logger = logging.getLogger(__name__)


def execute_publish(runtime: RuntimeInfo):
    logger.info("starting publish")

    for container_path in glob("./result/containers/*"):
        container_name = basename(container_path)
        store_path = realpath(container_path)
        container_item_id = VersionedItemId.container(container_name, runtime)

        logger.info(f"found container {container_name} with store_path {store_path}")
        version_result = update_version(container_item_id, store_path)

        if version_result["updated"]:
            logger.info(f"container changed, publishing")

            container_fullname = f"code.ramona.fun/ramona/{runtime.repository.name}/{container_name}:{runtime.now_timestamp}"
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
            version_result = update_version(
                VersionedItemId.npm_package(npm_name, runtime), store_path
            )

            # TODO also add a check on PRs to ensure version is bumped
            if version_result["updated"]:
                _ = run_command(["npm", "publish"])

    for iso_path in glob("./result/iso/*"):
        iso_name = basename(iso_path)
        container_item_id = VersionedItemId.container(iso_name, runtime)
        store_path = realpath(iso_path)
        version_result = update_version(container_item_id, store_path)

        logger.info(f"found iso {iso_name} with store path {store_path}")

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
            ignore_body=True,
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
            ignore_body=True,
        )
