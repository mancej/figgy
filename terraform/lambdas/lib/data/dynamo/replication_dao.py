from boto3.dynamodb.conditions import Key, Attr
from decimal import *
from config.constants import *
from typing import Dict, List, Optional
from lib.models.replication_config import ReplicationConfig, ReplicationType
from lib.models.run_env import RunEnv


# For interacting with the replication DDB table.
class ReplicationDao:
    def __init__(self, dynamo_resource):
        self._dynamo_resource = dynamo_resource
        self._table = self._dynamo_resource.Table(REPL_TABLE_NAME)

    def delete_config(self, destination, run_env) -> None:
        self._table.delete_item(
            Key={
                REPL_DEST_KEY_NAME: destination,
                REPL_RUN_ENV_KEY_NAME: run_env
            }
        )

    def get_all(self) -> List[ReplicationConfig]:
        result = self._table.scan()
        all_configs = result.get('Items', [])

        if 'LastEvaluatedKey' in result:
            result = self._table.scan(start_key=result['LastEvaluatedKey'])
            all_configs = all_configs + result.get('Items', [])

        if all_configs:
            all_configs = [ReplicationConfig.from_item(item) for item in all_configs]

        return all_configs

    def get_config_repl_by_source(self, source: str) -> List[ReplicationConfig]:
        filter_exp = Attr(REPL_SOURCE_ATTR_NAME).eq(source) & Attr(REPL_TYPE_ATTR_NAME).eq(REPL_TYPE_APP)

        result = self._table.scan(FilterExpression=filter_exp)
        items = result.get('Items', [])

        if 'LastEvaluatedKey' in result:
            result = self._table.scan(start_key=result['LastEvaluatedKey'])
            items = items + result.get('Items', [])

        results: List[ReplicationConfig] = []

        if items:
            results = [ReplicationConfig.from_item(item) for item in items]

        return results

    def get_configs_by_type(self, type: ReplicationType) -> List[ReplicationConfig]:
        filter_exp = Attr(REPL_TYPE_ATTR_NAME).eq(type.type)
        result = self._table.scan(FilterExpression=filter_exp)
        items = result.get('Items', [])

        if 'LastEvaluatedKey' in result:
            result = self._table.scan(FilterExpression=filter_exp, start_key=result['LastEvaluatedKey'])
            items = items + result.get('Items', [])

        results = []

        if items:
            results = [ReplicationConfig.from_item(item) for item in items]

        return results

    def get_config_repl(self, destination, run_env) -> Optional[ReplicationConfig]:
        filter_exp = Key(REPL_DEST_KEY_NAME).eq(destination) & \
                     Key(REPL_RUN_ENV_KEY_NAME).eq(run_env)
        result = self._table.query(KeyConditionExpression=filter_exp)
        item = {}

        if "Items" in result and len(result["Items"]) > 0:
            item = result["Items"][0]

            return ReplicationConfig.from_item(item)
        else:
            return None

    def put_config_repl(self, destination, svc_env, props) -> None:
        item = {
            REPL_DEST_KEY_NAME: destination,
            REPL_RUN_ENV_KEY_NAME: svc_env
        }

        for key in props:
            if key != REPL_DEST_KEY_NAME and key != REPL_RUN_ENV_KEY_NAME and not isinstance(props[key], float):
                item[key] = props[key]
            elif isinstance(props[key], float):
                item[key] = Decimal(f'{props[key]}')

        self._table.put_item(
            Item=item
        )
