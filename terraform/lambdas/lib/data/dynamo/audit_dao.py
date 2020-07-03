import time

from typing import Optional
from boto3.dynamodb.conditions import Attr

from config.constants import *


class AuditDao:
    def __init__(self, dynamo_resource):
        self._dynamo_resource = dynamo_resource
        self._table = self._dynamo_resource.Table(AUDIT_TABLE_NAME)

    def put_delete_log(self, user: str, action: str, ps_name: str):
        print(f"Storing delete event: {user} | {action} | {ps_name}")
        item = {
            AUDIT_PARAM_NAME_KEY: ps_name,
            AUDIT_EVENT_TYPE_ATTR: action,
            AUDIT_USER_ATTR: user,
            AUDIT_TIME_KEY: int(time.time() * 1000),
        }

        self._table.put_item(Item=item)

    def put_audit_log(
            self,
            user: str,
            action: str,
            ps_name: str,
            ps_value: Optional[str],
            ps_type: str,
            ps_key_id: Optional[str],
            ps_description: Optional[str],
            ps_version: str,
    ):

        item = {
            AUDIT_PARAM_NAME_KEY: ps_name,
            AUDIT_EVENT_TYPE_ATTR: action,
            AUDIT_USER_ATTR: user,
            AUDIT_TIME_KEY: int(time.time() * 1000),
            AUDIT_VALUE_ATTR: ps_value,
            AUDIT_TYPE_ATTR: ps_type,
            AUDIT_KEYID_ATTR: ps_key_id,
            AUDIT_DESCRIPTION_ATTR: ps_description,
            AUDIT_VERSION_ATTR: ps_version,
        }

        put_item = {}
        for key, value in item.items():
            if value:
                put_item[key] = value

        self._table.put_item(Item=put_item)

    # Should not go in this dao and should be moved...
    def cleanup_test_logs(self):
        filter_exp = Attr(AUDIT_VALUE_ATTR).eq(DELETE_ME_VALUE) | Attr(AUDIT_USER_ATTR).eq(CIRCLECI_USER_NAME)
        result = self._table.scan(FilterExpression=filter_exp)
        items = result["Items"] if result["Items"] else []

        for item in items:
            # if this record is older than TEST_VALUE_KEEP_TIME
            age_in_minutes = (int(time.time() * 1000) - item[AUDIT_TIME_KEY]) / 1000 / 60
            if age_in_minutes > TEST_VALUE_KEEP_TIME:
                print(f"Cleaning up: {item[AUDIT_PARAM_NAME_KEY]}")
                self._table.delete_item(
                    Key={AUDIT_PARAM_NAME_KEY: item[AUDIT_PARAM_NAME_KEY], AUDIT_TIME_KEY: item[AUDIT_TIME_KEY]}
                )
            else:
                print(
                    f"{item[AUDIT_PARAM_NAME_KEY]} is too young for cleanup - it's {age_in_minutes} minutes old. Waiting..."
                )
