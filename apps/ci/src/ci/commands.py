import logging
import subprocess

logger = logging.getLogger(__name__)


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
