from io import SEEK_SET
import tarfile
import tempfile
import botocore

from ci.runtime_info import RuntimeInfo


class DirectoryCache(object):
    _runtime: RuntimeInfo

    def __init__(self, runtime: RuntimeInfo) -> None:
        self._runtime = runtime

    def _make_path(self, branch: str, cache_key: str) -> str:
        return f"{self._runtime.repository_owner}/{self._runtime.repository_name}/{branch}/{cache_key}.tar.gz"

    def pull(self, cache_key: str) -> None:
        all_keys = [self._make_path("main", cache_key)]

        if self._runtime.branch != "main":
            all_keys.append(self._make_path(self._runtime.branch, cache_key))

        with tempfile.TemporaryFile() as file:
            while len(all_keys) > 0:
                key = all_keys.pop()

                print(f"trying: {key}")

                try:
                    self._runtime.cache_client.download_fileobj(
                        self._runtime.cache_bucket, key, file
                    )

                    break
                except (
                    botocore.exceptions.ClientError  # pyright: ignore[reportUnknownMemberType, reportAttributeAccessIssue]
                ) as error:  # pyright: ignore[reportUnknownVariableType]
                    if (
                        error.response["Error"]["Code"]
                        == "404"  # pyright: ignore[reportUnknownMemberType]
                    ):
                        if len(all_keys) > 0:
                            continue
                        else:
                            print(f"no cache found for key {cache_key}")

                            return

                    raise error

            _ = file.seek(SEEK_SET, 0)

            print(f"extracting")

            with tarfile.open(mode="r", fileobj=file) as tar:
                tar.extractall()

    def push(self, cache_key: str, path: str) -> None:
        if self._runtime.branch != "main":
            print("not on the main branch, not saving cache")

            return

        bucket_path = self._make_path("main", cache_key)
        print(f"uploading {path} to {bucket_path}")

        with tempfile.TemporaryFile() as file:
            with tarfile.open(fileobj=file, mode="w:gz") as tar:
                tar.add(path)

            _ = file.seek(SEEK_SET, 0)

            self._runtime.cache_client.upload_fileobj(
                file, self._runtime.cache_bucket, bucket_path
            )
        pass
