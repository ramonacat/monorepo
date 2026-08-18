from datetime import UTC, datetime
from os import environ
from pathlib import Path
from typing import override
import boto3
import botocore
from types_boto3_s3.client import S3Client

from ci.commands import run_command


def _read_env(name: str, default: str | None = None) -> str:
    result = environ.get(name)

    if result is None:
        if default is None:
            raise StartupError(f"environment variable {name} is not set")
        else:
            return default

    return result.replace("\\n", "\n")


def _indent(text: str, level: int = 1):
    lines = text.splitlines()
    indented = [" " * 4 * level + line for line in lines]

    return "\n".join(indented)


class StartupError(BaseException):
    pass


class S3Config(object):
    access_key_id: str
    secret_access_key: str

    def __init__(self, prefix: str) -> None:
        self.access_key_id = _read_env(prefix + "_ACCESS_KEY_ID")
        self.secret_access_key = _read_env(prefix + "_ACCESS_KEY_SECRET")


class PullRequestInfo(object):
    base: str

    def __init__(self, base: str) -> None:
        self.base = base

    @override
    def __str__(self) -> str:
        return f"base: {self.base}"


class RepositoryInfo(object):
    name: str
    owner: str
    url: str
    root: Path

    def __init__(self) -> None:
        self.name = _read_env("CI_REPO_NAME")
        self.owner = _read_env("CI_REPO_OWNER")
        self.url = _read_env("CI_REPO_URL")

        self.root = Path(run_command(["git", "rev-parse", "--show-toplevel"]).rstrip())

    @override
    def __str__(self) -> str:
        return (
            f"name: {self.name}\n"
            f"owner: {self.owner}\n"
            f"url: {self.url}\n"
            f"root: {self.root}"
        )


class RuntimeInfo(object):
    repository: RepositoryInfo

    branch: str

    cache_client: S3Client
    cache_bucket: str

    public_bucket: str

    attic_token: str
    github_token: str
    forgejo_token: str

    ssh_key: str

    now_timestamp: int
    pull_request: PullRequestInfo | None

    def __init__(self):

        self.repository = RepositoryInfo()

        self.branch = _read_env(
            "CI_COMMIT_SOURCE_BRANCH", _read_env("CI_REPO_DEFAULT_BRANCH")
        )

        s3_config = S3Config("CACHE")

        # https://docs.hetzner.com/storage/object-storage/getting-started/using-libraries/#aws-sdk-for-python-boto3
        self.cache_client = boto3.client(  # pyright: ignore[reportUnknownMemberType]
            "s3",
            region_name="nbg1",
            endpoint_url="https://nbg1.your-objectstorage.com",
            aws_access_key_id=s3_config.access_key_id,
            aws_secret_access_key=s3_config.secret_access_key,
            config=botocore.client.Config(  # pyright: ignore[reportUnknownMemberType, reportUnknownArgumentType, reportAttributeAccessIssue]
                signature_version="s3v4",
                s3={"payload_signing_enabled": False, "addressing_style": "virtual"},
            ),
        )

        self.cache_bucket = "ramona-woodpecker-cache"
        self.public_bucket = "ramona-public"

        self.attic_token = _read_env("ATTIC_TOKEN")
        self.github_token = _read_env("GITHUB_TOKEN")
        self.forgejo_token = _read_env("FORGEJO_TOKEN")
        self.ssh_key = _read_env("SSH_KEY")
        self.now_timestamp = round(
            (datetime.now(UTC) - datetime(1970, 1, 1, tzinfo=UTC)).total_seconds()
        )

        pull_request_base = _read_env("CI_COMMIT_SOURCE_BRANCH", "")
        if pull_request_base != "":
            self.pull_request = PullRequestInfo(pull_request_base)
        else:
            self.pull_request = None

    @override
    def __str__(self) -> str:
        str_pull_request = (
            ""
            if self.pull_request == None
            else f"pull_request:\n{_indent(str(self.pull_request))}\n"
        )
        return (
            f"repository: \n{_indent(str(self.repository))}\n"
            f"{str_pull_request}"
            f"branch: {self.branch}\n"
            f"cache_bucket: {self.cache_bucket}"
        )
