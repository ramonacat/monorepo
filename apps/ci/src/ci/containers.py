import subprocess


class UploadArchiveError(BaseException):
    pass


def upload_archive(path: str, name: str) -> None:
    result = subprocess.run(
        [
            "skopeo",
            "copy",
            f"docker-archive:{path}",
            f"docker://{name}",
        ]
    )

    if result.returncode != 0:
        raise UploadArchiveError(
            f"failed to upload archive {path} as {name}",
            {"stdout": result.stdout, "stderr": result.stderr},
        )
