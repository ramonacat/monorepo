from typing import TypedDict, cast, override

import requests

from ci.runtime_info import RuntimeInfo


class FailedRequest(Exception):
    pass


class VersionStatus(TypedDict):
    version: int
    updated: bool


# TODO this should be private and all the usages should be wrapped in specific functions
def api_post(url: str, json: object, ignore_body: bool = False) -> object:
    response = requests.post(url, json=json)

    if not response:
        raise FailedRequest(
            f"request to {url} failed with status {response.status_code}, response body:\n{response.text}"
        )

    if ignore_body:
        return {}

    return cast(object, response.json())


class VersionedItemId:
    _raw: str

    def __init__(self, category: str, item: str, runtime: RuntimeInfo) -> None:
        # TODO add repository owner and forge?
        self._raw = f"{runtime.repository.name}:{category}:{item}"

    @classmethod
    def container(cls, name: str, runtime: RuntimeInfo) -> VersionedItemId:
        return VersionedItemId("containers", name, runtime)

    @classmethod
    def npm_package(cls, name: str, runtime: RuntimeInfo) -> VersionedItemId:
        return VersionedItemId("npm-packages", name, runtime)

    @override
    def __str__(self) -> str:
        return self._raw


def update_version(versioned_item: VersionedItemId, store_path: str) -> VersionStatus:
    return cast(
        VersionStatus,
        api_post(
            "https://ras.infrastructure.ramona.fun/versions",
            json={"versioned_item": str(versioned_item), "store_path": store_path},
        ),
    )


def check_version(versioned_item: VersionedItemId, store_path: str) -> VersionStatus:
    return cast(
        VersionStatus,
        api_post(
            "https://ras.infrastructure.ramona.fun/versions/actions/check",
            json={"versioned_item": str(versioned_item), "store_path": store_path},
        ),
    )
