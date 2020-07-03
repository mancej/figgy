import re
from config.constants import *
from lib.data.dynamo.replication_dao import ReplicationDao
from lib.data.ssm.ssm import SsmDao
from urllib.parse import quote_plus, urlencode
from lib.models.replication_config import ReplicationConfig


class ReplicationService:

    def __init__(self, replication_dao: ReplicationDao, ssm: SsmDao):
        self._replication_dao = replication_dao
        self._ssm = ssm

    def sync_config(self, config: ReplicationConfig) -> bool:
        """
        Ensures a replication configuration is synchronized. Returns True if any action to sync the config takes place,
        False otherwise.
        :param config: Defined replication config to ensure is synchronized.
        :return: True/False. True is returned if a change is maded in PS to sync this config.
        """
        dest_param = self._ssm.get_parameter(config.destination)
        dest_val = dest_param['Parameter']['Value'] if dest_param else None
        dest_type = dest_param['Parameter']['Type'] if dest_param else None

        if config.type == REPL_TYPE_MERGE:
            src_type = SSM_SECURE_STRING
            src_val = self.get_merge_value(config.source)
        else:
            src_param = self._ssm.get_parameter(config.source)
            src_val = src_param['Parameter']['Value'] if src_param else None
            src_type = src_param['Parameter']['Type'] if src_param else None

        if (dest_val != src_val and src_val is not None) or \
                (dest_type != src_type and src_val is not None):
            self.replicate_config(config.source, config.destination,
                                  src_type, src_val, config.user)
            return True
        else:
            print(f"{config.source} -> {config.destination} is valid")

        return False

    def replicate_config(self, source, dest, src_type, src_val, user):
        desc = f"Replicated from: {source} by: {user}"
        if src_type == REPL_TYPE_MERGE:
            merge_val = self.get_merge_value(src_val)
            self._ssm.set_parameter(dest, merge_val, desc, src_type,
                                    key_id=self._ssm.get_parameter_value(REPL_KEY_PS_PATH))
        else:
            self._ssm.set_parameter(dest, src_val, desc, src_type,
                                    key_id=self._ssm.get_parameter_value(REPL_KEY_PS_PATH))

    def get_value(self, ps_key: str):
        if ps_key.endswith(":uri"):
            ps_key = ps_key[:-4]
            ps_val = self._ssm.get_parameter_value(ps_key)
            if ps_val is not None:
                ps_val = quote_plus(ps_val, encoding='utf-8')
        else:
            ps_val = self._ssm.get_parameter_value(ps_key)

        return ps_val

    def get_merge_value(self, merge_val):
        merged_key = ""
        if isinstance(merge_val, list):
            for key in merge_val:
                match = re.match("^\${(/.*)}$", key)
                if match is not None:
                    ps_name = match.group(1)
                    ps_val = self.get_value(ps_name)
                    ps_val = ps_val if ps_val else f"KEY: {ps_name} is missing. Cannot complete merge key."
                    merged_key = merged_key + ps_val
                else:
                    merged_key = merged_key + key
        else:
            matches = re.findall('\${([\w/-]+)}', merge_val)
            for ps_name in matches:
                ps_val = self.get_value(ps_name)
                set_val = ps_val if ps_val else f"KEY: {ps_name} is missing. Cannot complete merge key."
                merge_val = merge_val.replace(f"{ps_name}", set_val)

            merged_key = merge_val

        return merged_key
