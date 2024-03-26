"""
This type stub file was generated by pyright.
"""

import asyncio
from typing import Callable, Dict

"""Uart module."""
LOGGER = ...
class Gateway(asyncio.Protocol):
    END = ...
    ESC = ...
    ESC_END = ...
    ESC_ESC = ...
    def __init__(self, api, connected_future=...) -> None:
        """Initialize instance of the UART gateway."""
        ...
    
    def connection_lost(self, exc) -> None:
        """Port was closed expectedly or unexpectedly."""
        ...
    
    def connection_made(self, transport): # -> None:
        """Call this when the uart connection is established."""
        ...
    
    def close(self): # -> None:
        ...
    
    def send(self, data): # -> None:
        """Send data, taking care of escaping and framing."""
        ...
    
    def data_received(self, data): # -> None:
        """Handle data received from the uart."""
        ...
    


async def connect(config: Dict[str, any], api: Callable) -> Gateway:
    ...
