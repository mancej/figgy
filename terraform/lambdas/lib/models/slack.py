from abc import abstractmethod, ABC
from typing import Dict

from dataclasses import dataclass
from enum import Enum
from typing import Optional

from lib.models.replication_config import ReplicationConfig


class SlackColor(Enum):
    GREEN = '#30C22E'
    ORANGE = '#F99548'
    RED = '#D93A4D'


@dataclass
class SlackMessage(ABC):
    @abstractmethod
    def slack_format(self) -> Dict:
        pass


@dataclass
class SimpleSlackMessage(SlackMessage):
    """
    Represents a lightly configurable slack message that can be submitted via the SlackService to a
    configured webhook url.
    """
    message: str
    color: SlackColor
    title: str

    def slack_format(self):
        return {
            "attachments": [
                {
                    "attachment_type": "default",
                    "title": f"{self.title}",
                    "text": f"{self.message}",
                    "color": f"{self.color.value}"
                }
            ]
        }


@dataclass
class FigReplicationMessage(SlackMessage):
    replication_cfg: ReplicationConfig
    triggering_user: Optional[str] = None

    def slack_format(self):
        extra_note = ""
        if self.triggering_user:
            extra_note = f"This update was triggered by a chance to the source fig by: *{self.triggering_user}*\n"

        text = f"*Source*:   `{self.replication_cfg.source}`\n" \
               f"*Dest*:       `{self.replication_cfg.destination}`\n" \
               f"*Owner*:   `{self.replication_cfg.user}`\n" \
               f"{extra_note}" \
               f"For more information on what this means, check out the " \
               "<https://www.figgy.dev/docs/getting-started/basics/#the-solution-config-replication|Figgy Docs>"

        return \
            {
                "attachments": [
                    {
                        "color": SlackColor.GREEN.value,
                        "blocks": [
                            {
                                "type": "section",
                                "text": {
                                    "type": "mrkdwn",
                                    "text": "*Figgy Event:* Fig successfully replicated by Figgy."
                                }
                            },
                            {
                                "type": "divider"
                            },
                            {
                                "type": "section",
                                "text": {
                                    "type": "mrkdwn",
                                    "text": text
                                },
                                "accessory": {
                                    "type": "image",
                                    "image_url": "https://www.figgy.dev/assets/img/sample/logo-black.png",
                                    "alt_text": "Figgy"
                                }
                            },
                            {
                                "type": "context",
                                "elements": [
                                    {
                                        "type": "mrkdwn",
                                        "text": "*FigBot* has approved this message."
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }


@dataclass
class FigDeletedMessage(SlackMessage):
    name: str
    user: str
    environment: str

    def slack_format(self):
        return \
            {
                "attachments": [
                    {
                        "color": SlackColor.ORANGE.value,
                        "blocks": [
                            {
                                "type": "section",
                                "text": {
                                    "type": "mrkdwn",
                                    "text": "*Figgy Event:* Configuration Deleted"
                                }
                            },
                            {
                                "type": "divider"
                            },
                            {
                                "type": "section",
                                "text": {
                                    "type": "mrkdwn",
                                    "text": f"*Deleted*:    `{self.name}`\n"
                                            f"*By User*:    `{self.user}`\n"
                                            f"The above configuration was deleted in the *{self.environment}*"
                                            f" environment."
                                },
                                "accessory": {
                                    "type": "image",
                                    "image_url": "https://www.figgy.dev/assets/img/sample/logo-black.png",
                                    "alt_text": "Figgy"
                                }
                            }
                        ]
                    }
                ]
            }
