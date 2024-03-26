"""
This type stub file was generated by pyright.
"""

import typing
from zigpy.exceptions import APIException
from zigpy_deconz.api import Command, CommandId, Status

"""Zigpy-deconz exceptions."""
if typing.TYPE_CHECKING:
    ...
class CommandError(APIException):
    def __init__(self, *args, status: Status, command: Command, **kwargs) -> None:
        """Initialize instance."""
        ...
    


class ParsingError(CommandError):
    ...


class MismatchedResponseError(APIException):
    def __init__(self, command_id: CommandId, params: dict[str, typing.Any], *args, **kwargs) -> None:
        """Initialize instance."""
        ...
    

