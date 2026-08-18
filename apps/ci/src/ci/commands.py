import logging
import subprocess
from time import sleep
from typing import Callable, cast

logger = logging.getLogger(__name__)


def retry[T](callback: Callable[[], T]) -> T:
    i: int = 0
    while True:
        try:
            return callback()
        except Exception as e:
            if i == 5:
                raise Exception("retries exhausted", e)
            i += 1
            sleep(cast(int, 2**i))


class RunCommandError(Exception):
    pass


def run_command(command: list[str], silent: bool = True) -> str:
    logger.info(f"running {command}")

    result = subprocess.run(command, capture_output=True)

    if result.returncode != 0:
        raise RunCommandError(
            f"failed to run {command}",
            {
                "stdout": result.stdout.decode("utf-8"),
                "stderr": result.stderr.decode("utf-8"),
            },
        )
    elif not silent:
        logger.info(
            f"command exectued, stdout:\n{result.stdout.decode('utf-8')}\nstderr:\n{result.stderr.decode('utf-8')}\n"
        )

    return result.stdout.decode("utf-8")
