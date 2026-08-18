import logging

import igittigitt
from contextlib import chdir

from ci.app import AppRoot
from ci.commands import run_command

logger = logging.getLogger(__name__)


class CheckError(BaseException):
    pass


def run_checks(roots: list[AppRoot]):
    for root in roots:
        logger.info(f"runnning checks for {root["path"]}")

        if "nix" in root["config"]:
            check_nix(root)

        if "nodejs" in root["config"]:
            check_nodejs(root)

        if "terraform" in root["config"]:
            check_terraform(root)

        if "rust" in root["config"]:
            check_rust(root)

        if "python" in root["config"]:
            check_python(root)

        if "shell" in root["config"]:
            check_shell(root)


def check_nix(root: AppRoot):
    with chdir(root["path"].parent):
        _ = run_command(["nix", "fmt", "--", "--fail-on-change"])
        _ = run_command(["nix", "flake", "check"])


def check_nodejs(root: AppRoot):
    path = root["path"].parent
    with chdir(path):
        _ = run_command(["npm", "install"])
        _ = run_command(["npm", "run", "check"])


def check_terraform(root: AppRoot):
    with chdir(root["path"].parent):
        _ = run_command(["terraform", "init"])
        _ = run_command(["terraform", "fmt", "-recursive", "-check", "-diff", "."])
        _ = run_command(["tflint", "--init"])
        _ = run_command(["tflint"])
        _ = run_command(["terraform", "validate"])


def check_rust(root: AppRoot):
    with chdir(root["path"].parent):
        _ = run_command(["cargo", "fmt", "--check"])
        _ = run_command(["cargo", "clippy"])


def check_python(root: AppRoot):
    with chdir(root["path"].parent):
        _ = run_command(["uv", "run", "black", "--check", "."])
        _ = run_command(["uv", "run", "pyright"])


def check_shell(root: AppRoot):
    with chdir(root["path"].parent):
        _ = run_command(["shfmt", "--list", "--apply-ignore", "."])

        gitignore = igittigitt.IgnoreParser()
        gitignore.parse_rule_files(root["path"].parent)

        shell_scripts = [
            path
            for path in root["path"].parent.rglob("*")
            if (path.suffix in [".sh", ".bash"] and not gitignore.match(path))
        ]

        _ = run_command(["shellcheck"] + [str(path) for path in shell_scripts])
