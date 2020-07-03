import time
import logging
from dataclasses import dataclass
from enum import Enum

from boto3.dynamodb.conditions import Key

from lib.utils.utils import Utils
from typing import Set, Dict, List

from config.constants import *

log = Utils.get_logger(__name__, logging.INFO)


class ConfigState(Enum):
    DELETED = 0
    ACTIVE = 1


@dataclass(eq=True, frozen=True)
class ConfigItem:
    name: str
    state: ConfigState
    last_updated: int

    @staticmethod
    def from_dict(obj: Dict) -> "ConfigItem":
        name = obj.get(CONFIG_CACHE_PARAM_NAME_KEY, None)
        last_updated = obj.get(CONFIG_CACHE_LAST_UPDATED_KEY, int(time.time() * 1000))
        state = obj.get(CONFIG_CACHE_STATE_ATTR_NAME, ConfigState.ACTIVE.name)

        return ConfigItem(name=name, last_updated=last_updated, state=ConfigState[state])

    def __lt__(self, other):
        if isinstance(other, ConfigItem):
            return other.last_updated > self.last_updated
        else:
            raise ValueError(f"Cannot compare {self.__class__} against {other.__class__}")

    def __gt__(self, other):
        if isinstance(other, ConfigItem):
            return other.last_updated < self.last_updated
        else:
            raise ValueError(f"Cannot compare {self.__class__} against {other.__class__}")



class ConfigCacheDao:

    def __init__(self, ddb_resource):
        self._dynamo_resource = ddb_resource
        self._cache_table = self._dynamo_resource.Table(CONFIG_CACHE_TABLE_NAME)

    def delete(self, item: ConfigItem) -> None:
        self._cache_table.delete_item(Key={
            CONFIG_CACHE_PARAM_NAME_KEY: item.name,
            CONFIG_CACHE_LAST_UPDATED_KEY: item.last_updated
        })

    def get_items(self, name: str) -> Set[ConfigItem]:
        """
        Returns all matching items by name, this should almost always be exactly 1 item, but in theory due to table
        structure we could have 2 items with 1 name.
        :param name: parameter name to query by
        :return: Set[ConfigItem] - Set of items that match.
        """
        filter_exp = Key(CONFIG_CACHE_PARAM_NAME_KEY).eq(name)
        result = self._cache_table.query(KeyConditionExpression=filter_exp)
        items: Set[ConfigItem] = set()
        if "Items" in result and len(result['Items']) > 0:
            for item in result['Items']:
                items.add(ConfigItem.from_dict(item))

        return items

    def mark_deleted(self, item: ConfigItem) -> None:
        """
        Marks an item as "DELETED" in the DB and resets the last_updated time. This will prompt the CLI to remove
        this item from its local cache on next invocation.
        """
        self.delete(item)
        self.put_in_cache(item.name, state=CONFIG_CACHE_STATE_DELETED)

    def put_in_cache(self, name: str, state=CONFIG_CACHE_STATE_ACTIVE):
        """
        Stores a new parameter into the cache table and sets the last_updated to now
        :param name: Name of parameter to store
        :param state: state to set in the cache
        """
        item = {
            CONFIG_CACHE_PARAM_NAME_KEY: name,
            CONFIG_CACHE_STATE_ATTR_NAME: state,
            CONFIG_CACHE_LAST_UPDATED_KEY: int(time.time() * 1000)
        }

        self._cache_table.put_item(Item=item)

    def get_deleted_configs(self) -> List[ConfigItem]:
        all_configs = self.get_all_configs()
        return [config for config in all_configs if config.state == ConfigState.DELETED]

    def get_all_configs(self, start_key: str = None) -> Set[ConfigItem]:
        """
        Retrieve all key names from the Dynamo DB config-cache table in each account. Much more efficient than
        querying SSM directly.
        Args:
            start_key: Optional: Is used for recursive paginated lookups to get the full data set. This should not
            be passed in by the user.
        Returns:

        """
        start_time = time.time()
        if start_key:
            log.info(f"Recursively scanning with start key: {start_key}")
            result = self._cache_table.scan(ExclusiveStartKey=start_key)
        else:
            result = self._cache_table.scan()

        configs: Set[ConfigItem] = set()
        if "Items" in result and len(result['Items']) > 0:
            for item in result['Items']:
                configs.add(ConfigItem.from_dict(item))

        if 'LastEvaluatedKey' in result:
            configs = configs | self.get_all_configs(start_key=result['LastEvaluatedKey'])

        log.info(
            f"Returning config names from dynamo cache after: {time.time() - start_time} "
            f"seconds with {len(configs)} configs.")

        return configs
