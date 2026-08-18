from typing import TypedDict, cast

import requests


class FailedRequest(Exception):
    pass


class VersionStatus(TypedDict):
    version: int
    updated: bool


def api_post(url: str, json: object, ignore_body: bool = False) -> object:
    response = requests.post(url, json=json)

    if not response:
        raise FailedRequest(
            f"request to {url} failed with status {response.status_code}, response body:\n{response.text}"
        )

    if ignore_body:
        return {}

    return cast(object, response.json())


def post_version(versioned_item: str, store_path: str) -> VersionStatus:
    return cast(
        VersionStatus,
        api_post(
            "https://ras.infrastructure.ramona.fun/versions",
            json={"versioned_item": versioned_item, "store_path": store_path},
        ),
    )
