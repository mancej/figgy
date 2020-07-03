import json
import logging
from botocore.vendored import requests
from lib.models.slack import SlackMessage, SlackColor
from lib.utils.utils import Utils

log = Utils.get_logger(__name__, logging.INFO)


class SlackService:
    def __init__(self, webhook_url: str):
        self.webhook_url = webhook_url

    def send_message(self, message: SlackMessage):
        if self.webhook_url:
            slack_message = {
                "attachments": [
                    {
                        "attachment_type": "default",
                        "title": f"{message.title}",
                        "text": f"{message.message}",
                        "color": f"{message.color.value}"
                    }
                ]
            }

            requests.post(self.webhook_url, json.dumps(slack_message))
        else:
            log.warning(f"Slack webhook unconfigured. Ignoring effort to submit Slack Notification.")

    def send_error(self, title: str, message: str):
        if self.webhook_url:
            slack_message = {
                "attachments": [
                    {
                        "attachment_type": "default",
                        "title": f"{title}",
                        "text": f"{message}",
                        "color": f"{SlackColor.RED.value}"
                    }
                ]
            }
            requests.post(self.webhook_url, json.dumps(slack_message))
        else:
            log.warning(f"Slack webhook unconfigured. Ignoring effort to submit Slack Notification.")
