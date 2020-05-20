import re
import xml.etree.ElementTree as ET

from config.sso import *
from dataclasses import dataclass
from typing import Optional, Any, List

from models.assumable_role import AssumableRole
from models.role import Role
from models.run_env import RunEnv
from svcs.sso.google.google import Google

from models.defaults.defaults import CLIDefaults
from svcs.cache_manager import CacheManager
from svcs.sso.provider.sso_session_provider import SSOSessionProvider
from utils.secrets_manager import SecretsManager
from utils.utils import Utils


@dataclass
class GoogleConfig:
    username: str
    password: str
    idp_id: str
    sp_id: str
    bg_response: Optional[str]


class GoogleSessionProvider(SSOSessionProvider):
    _SESSION_CACHE_KEY = 'session'
    _SAML_CACHE_KEY = 'saml_assertion'
    _SAML_MAX_AGE = 60 * 60 * 8 * 1000  # 12 hours

    def __init__(self, defaults: CLIDefaults):
        super().__init__(defaults)
        self._cache_manager: CacheManager = CacheManager(file_override=GOOGLE_SESSION_CACHE_PATH)
        config = GoogleConfig(
            username=defaults.user,
            password=SecretsManager.get_password(defaults.user),
            idp_id=defaults.provider_config.idp_id,
            sp_id=defaults.provider_config.sp_id,
            bg_response=None)

        self._google = Google(config=config, save_failure=False)
        self._write_google_session_to_cache(self._google.session_state)

    def _write_google_session_to_cache(self, session: Any):
        self._cache_manager.write(self._SESSION_CACHE_KEY, session)

    def get_assumable_roles(self):
        saml = self._google.parse_saml()
        decoded_assertion = saml.decode('utf-8')
        root = ET.fromstring(decoded_assertion)
        prefix_map = {"saml2": "urn:oasis:names:tc:SAML:2.0:assertion"}
        role_attribute = root.find(".//saml2:Attribute[@Name='https://aws.amazon.com/SAML/Attributes/Role']",
                                   prefix_map)

        # SAML arns should look something like this:
        # arn:aws:iam::9999999999:role/figgy-dev-devops,arn:aws:iam::9999999999:saml-provider/google
        pattern = r'^arn:aws:iam::([0-9]+):role/(\w+-(\w+)-(\w+)),.*saml-provider/(\w+)'
        assumable_roles: List[AssumableRole] = []
        for value in role_attribute.findall('.//saml2:AttributeValue', prefix_map):
            result = re.search(pattern, value.text)
            unparsable_msg = f'{value.text} is of an invalid pattern, it must match: {pattern} for figgy to ' \
                             f'dynamically map account_id -> run_env -> role for OKTA users.'
            if not result:
                Utils.stc_error_exit(unparsable_msg)

            result.groups()
            account_id, role_name, run_env, role, provider_name = result.groups()

            if not account_id or not run_env or not role_name or not role:
                Utils.stc_error_exit(unparsable_msg)
            else:
                assumable_roles.append(AssumableRole(account_id=account_id,
                                                     role=Role(role, full_name=role_name),
                                                     run_env=RunEnv(run_env),
                                                     provider_name=provider_name))
        return assumable_roles

    def _get_decoded_saml(self) -> str:
        self._google.do_login()
        return self._google.parse_saml().decode('utf-8')

    def get_saml_assertion(self, prompt: bool = False) -> str:
        return self._cache_manager.get_val_or_refresh(self._SAML_CACHE_KEY, self._get_decoded_saml,
                                                      max_age=self._SAML_MAX_AGE)

    def cleanup_session_cache(self):
        self._write_google_session_to_cache(None)