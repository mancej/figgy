import logging
import time
from typing import List

import boto3

from lib.data.dynamo.replication_dao import ReplicationDao
from lib.data.ssm.ssm import SsmDao
from lib.models.replication_config import ReplicationConfig
from lib.svcs.replication import ReplicationService
from lib.svcs.slack import SlackService
from lib.models.slack import SlackColor, SlackMessage, FigReplicationMessage, SimpleSlackMessage
from config.constants import FIGGY_WEBHOOK_URL_PATH
from lib.utils.utils import Utils

repl_dao: ReplicationDao = ReplicationDao(boto3.resource('dynamodb'))
ssm: SsmDao = SsmDao(boto3.client('ssm'))
repl_svc: ReplicationService = ReplicationService(repl_dao, ssm)

webhook_url = ssm.get_parameter_value(FIGGY_WEBHOOK_URL_PATH)
slack: SlackService = SlackService(webhook_url=webhook_url)
log = Utils.get_logger(__name__, logging.INFO)


def notify_slack(config: ReplicationConfig):
    message = FigReplicationMessage(replication_cfg=config)
    slack.send_message(message)


def handle(event, context):
    try:
        repl_configs: List[ReplicationConfig] = repl_dao.get_all()
        for config in repl_configs:
            time.sleep(.15)  # This is to throttle PS API Calls to prevent overloading the API.
            updated = repl_svc.sync_config(config)

            if updated:
                notify_slack(config)
    except Exception as e:
        log.error(e)
        title = "Figgy experienced an irrecoverable error!"
        message=f"The following error occurred in an the *figgy-replication-syncer* lambda. " \
                f"If this appears to be a bug with figgy, please tell us by submitting a GitHub issue!" \
                f" \n\n```{Utils.printable_exception(e)}```"
        message = SimpleSlackMessage(title=title, message=message, color=SlackColor.RED)
        slack.send_message(message)
        raise e


if __name__ == '__main__':
    handle(None, None)
