from dataclasses import dataclass
from enum import Enum


class SlackColor(Enum):
    GREEN = 'good'
    ORANGE = 'warning'
    RED = 'danger'

@dataclass
class SlackMessage:
    """
    Represents a lightly configurable slack message that can be submitted via the SlackService to a
    configured webhook url.
    """
    title: str
    color: SlackColor
    message: str