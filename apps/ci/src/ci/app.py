import json
from pathlib import Path
from typing import Final, NotRequired, TypedDict

CONFIG_FILENAME: Final[str] = ".ramonarc.json"


class NixConfig(TypedDict):
    pass


class NodejsConfig(TypedDict):
    pass


class TerraformConfig(TypedDict):
    pass


class RustConfig(TypedDict):
    pass


class PythonConfig(TypedDict):
    pass


class ShellConfig(TypedDict):
    pass


class AppConfig(TypedDict):
    nix: NotRequired[NixConfig]
    nodejs: NotRequired[NodejsConfig]
    terraform: NotRequired[TerraformConfig]
    rust: NotRequired[RustConfig]
    python: NotRequired[PythonConfig]
    shell: NotRequired[ShellConfig]


class AppRoot(TypedDict):
    is_repository_root: bool
    path: Path
    config: AppConfig


def find_roots(repository_root: Path) -> list[AppRoot]:
    roots: list[AppRoot] = []

    for config_path in repository_root.rglob(CONFIG_FILENAME):
        with open(config_path, "r") as file:
            parsed_config: AppConfig = json.load(file)  # pyright: ignore[reportAny]
            roots.append(
                {
                    "is_repository_root": repository_root == config_path.parent,
                    "path": config_path,
                    "config": parsed_config,
                }
            )

    return roots
