from os import environ
from typing import override
import boto3
import botocore
from types_boto3_s3.client import S3Client


def _read_env(name: str, default: str | None = None) -> str:
    result = environ.get(name)

    if result is None:
        if default is None:
            raise StartupError(f"environment variable {name} is not set")
        else:
            return default

    return result.replace("\\n", "\n")


class StartupError(BaseException):
    pass


class S3Config(object):
    access_key_id: str
    secret_access_key: str

    def __init__(self, prefix: str) -> None:
        self.access_key_id = _read_env(prefix + "_ACCESS_KEY_ID")
        self.secret_access_key = _read_env(prefix + "_ACCESS_KEY_SECRET")


class RuntimeInfo(object):
    repository_name: str
    repository_owner: str
    repository_url: str

    branch: str

    cache_client: S3Client
    cache_bucket: str

    attic_token: str
    github_token: str
    forgejo_token: str

    ssh_key: str

    def __init__(self):
        self.repository_name = _read_env("CI_REPO_NAME")
        self.repository_owner = _read_env("CI_REPO_OWNER")
        self.repository_url = _read_env("CI_REPO_URL")

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
        self.attic_token = _read_env("ATTIC_TOKEN")
        self.github_token = _read_env("GITHUB_TOKEN")
        self.forgejo_token = _read_env("FORGEJO_TOKEN")
        self.ssh_key = _read_env("SSH_KEY")

    @override
    def __str__(self) -> str:
        return (
            f"repository_name: {self.repository_name}\n"
            f"repository_owner: {self.repository_owner}\n"
            f"repository_url: {self.repository_url}\n"
            f"branch: {self.branch}\n"
            f"cache_bucket: {self.cache_bucket}"
        )
