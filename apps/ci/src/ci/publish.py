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


def _publish_to_bucket(path: Path, name: str, runtime: RuntimeInfo):
    with open(path, "rb") as file:
        runtime.cache_client.upload_fileobj(
            file,
            runtime.public_bucket,
            f"publish/{runtime.repository.owner}/{runtime.repository.name}/{name}",
        )


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

    for npm_path in Path("./result/npm-packages/").glob("*"):
        npm_path = npm_path.absolute()

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

            iso_path = Path(store_path).glob("iso/*.iso")

            _publish_to_bucket(
                next(iso_path), re.sub("^(nixos-.*?)-\\d.*", "\\1", iso_name), runtime
            )

    for apk_path in Path("./result/apk").glob("*"):
        app_name = basename(apk_path)
        apk_item_id = VersionedItemId.apk(app_name, runtime)
        store_path = realpath(apk_path)

        logger.info(f"found apk {app_name} with store path {store_path}")
        version_result = update_version(apk_item_id, store_path)

        if version_result["updated"]:
            logger.info("apk changed, publishing")

            _publish_to_bucket(apk_path / "debug.apk", f"{app_name}/debug.apk", runtime)
            _publish_to_bucket(
                apk_path / "release.apk", f"{app_name}/release.apk", runtime
            )

    for closure_path in glob("./result/hosts/*"):
        home_name = basename(closure_path)
        store_path = realpath(closure_path)

        logger.info(
            f"found nixos configuration {home_name} with store path {store_path}, publishing"
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
            f"found home-manager configuration {home_name} with store path {store_path}, publishing"
        )

        # TODO do a diff and post as PR comment
        _ = api_post(
            f"https://ras.infrastructure.ramona.fun/homes/{home_name}/latest_closure",
            json={"latest_closure": store_path},
            ignore_body=True,
        )
