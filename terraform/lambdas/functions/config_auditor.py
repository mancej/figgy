import random
import boto3
import logging
from config.constants import *
from lib.models.replication_config import ReplicationConfig
from lib.data.dynamo.audit_dao import AuditDao
from lib.data.ssm import SsmDao
from lib.models.slack import SlackMessage, SlackColor
from lib.svcs.slack import SlackService
from lib.utils.utils import Utils

log = Utils.get_logger(__name__, logging.INFO)

dynamo_resource = boto3.resource("dynamodb")
audit: AuditDao = AuditDao(dynamo_resource)
ssm_client = boto3.client('ssm')
ssm = SsmDao(ssm_client)
webhook_url = ssm.get_parameter_value(FIGGY_WEBHOOK_URL_PATH)
slack: SlackService = SlackService(webhook_url=webhook_url)

ACCOUNT_ID = ssm.get_parameter_value(ACCOUNT_ID_PS_PATH)
ACCOUNT_ENV = ssm.get_parameter_value(ACCOUNT_ENV_PS_PATH)
NOTIFY_DELETES = ssm.get_parameter_value(NOTIFY_DELETES_PS_PATH)
NOTIFY_DELETES = NOTIFY_DELETES.lower() == "true" if NOTIFY_DELETES else False

def notify_delete(ps_name: str, user: str):
    if NOTIFY_DELETES:
        message = SlackMessage(
            color=SlackColor.ORANGE,
            title="Figgy Event: Fig Deleted.",
            message=f"Fig: {ps_name} was deleted by: {user} in account: {ACCOUNT_ENV}"
        )

        slack.send_message(message)


def handle(event, context):
    # Don't process other account's events.
    originating_account = event.get('account')
    if originating_account != ACCOUNT_ID:
        log.info(f"Received event from different account with id: {ACCOUNT_ID}. Skipping this event.")
        return

    try:
        log.info(f"Event: {event}")
        detail = event["detail"]
        user_arn = detail["userIdentity"]["arn"]
        user = user_arn.split("/")[-1:][0]
        action = detail["eventName"]

        if 'errorMessage' in detail:
            log.info(f'Not processing event due to this being an error event with message: {detail["errorMessage"]}')
            return

        ps_name = detail.get('requestParameters', {}).get('name')

        if ps_name:
            if action == DELETE_PARAM_ACTION or action == DELETE_PARAMS_ACTION:
                audit.put_delete_log(user, action, ps_name)
                notify_delete(ps_name, user)
            elif action == PUT_PARAM_ACTION:
                ps_value = (
                    detail["requestParameters"]["value"]
                    if "value" in detail["requestParameters"]
                    else None
                )
                ps_type = detail["requestParameters"]["type"]
                ps_description = (
                    detail["requestParameters"]["description"]
                    if "description" in detail["requestParameters"]
                    else None
                )
                ps_version = detail["responseElements"]["version"]
                ps_key_id = (
                    detail["requestParameters"]["keyId"]
                    if "keyId" in detail["requestParameters"]
                    else None
                )

                if not ps_value:
                    ps_value = get_parameter_value(ps_name)

                audit.put_audit_log(
                    user,
                    action,
                    ps_name,
                    ps_value,
                    ps_type,
                    ps_key_id,
                    ps_description,
                    ps_version,
                )
            else:
                log.info(f"Unsupported action type found! --> {action}")

            # this requires a table scan, so don't do this _EVERY_ run. No big deal. 1 in 30 chance.
        if random.randint(1, 30) == 3:
            log.info("Cleaning up.")
            audit.cleanup_test_logs()
        else:
            log.info("Skipping cleanup.")

    except Exception as e:
        log.error(e)
        slack.send_error(title="Figgy experienced an irrecoverable error!",
                         message=f"The following error occurred in an the figgy-ssm-stream-replicator lambda. "
                                 f"If this appears to be a bug with figgy, please tell us by submitting a GitHub issue!"
                                 f" \n\n{Utils.printable_exception(e)}")
        raise e


def get_parameter_value(key):
    ssm = boto3.client("ssm")
    parameter = ssm.get_parameter(Name=key, WithDecryption=False)
    return parameter["Parameter"]["Value"]


if __name__ == "__main__":
    handle(None, None)
