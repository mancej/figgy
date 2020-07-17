from pathlib import Path

VERSION = '0.0.30a'
CLI_NAME = 'figgy'
PROJECT_NAME = 'figgy'

# Figgy URLS
FIGGY_GITHUB = "https://github.com/mancej/figgy"
FIGGY_OBS_API_BASE_URL = "https://api.figgy.dev"

# Paths
FIGGY_ERROR_REPORTING_URL = f"{FIGGY_OBS_API_BASE_URL}/v1/log-error"
FIGGY_GET_VERSION_URL = f"{FIGGY_OBS_API_BASE_URL}/v1/version"
FIGGY_LOG_METRICS_URL = f"{FIGGY_OBS_API_BASE_URL}/v1/log-metrics"

# Role names are assumed to be prefixed with `figgy-` - Users may override by setting the below ENV variable.
FIGGY_ROLE_NAME_PREFIX = 'figgy-'
FIGGY_ROLE_PREFIX_OVERRIDE_ENV = 'FIGGY_ROLE_PREFIX_OVERRIDE'

# TODO: UPDATE THIS

# Table-specific Constants
REPL_TABLE_NAME = "figgy-config-replication"
REPL_DEST_KEY_NAME = "destination"
REPL_RUN_ENV_KEY_NAME = "env_alias"
REPL_SOURCE_ATTR_NAME = "source"
REPL_NAMESPACE_ATTR_NAME = "namespace"
REPL_TYPE_ATTR_NAME = "type"
REPL_TYPE_APP = "app"
REPL_TYPE_MERGE = "merge"
REPL_USER_ATTR_NAME = "user"

AUDIT_TABLE_NAME = "figgy-config-auditor"
AUDIT_PARAMETER_KEY_NAME = "parameter_name"
AUDIT_TIME_KEY_NAME = "time"
AUDIT_ACTION_ATTR_NAME = "action"
AUDIT_USER_ATTR_NAME = "user"

CACHE_TABLE_NAME = 'figgy-config-cache'
CACHE_PARAMETER_KEY_NAME = "parameter_name"
CACHE_LAST_UPDATED_KEY_NAME = "last_updated"
CACHE_STATE_ATTR_NAME = 'state'
AUDIT_PARAMETER_ATTR_TYPE = "type"
AUDIT_PARAMETER_ATTR_VERSION = "version"
AUDIT_PARAMETER_ATTR_DESCRIPTION = "description"
AUDIT_PARAMETER_ATTR_VALUE = "value"
AUDIT_PARAMETER_ATTR_KEY_ID = "key_id"

# Merge Key constants
MERGE_KEY_PREFIX = "${"
MERGE_KEY_SUFFIX = "}"

# SSM Constants
SSM_SECURE_STRING = "SecureString"
SSM_STRING = "String"
SSM_PUT = 'PutParameter'
SSM_DELETE = 'DeleteParameter'

# Other PS Config constants
DEPLOY_GROUPS_PS_PREFIX = '/shared/deploy-groups/'

# figgy.json json keys
REPLICATION_KEY = 'replicate_figs'
MERGE_KEY = 'merged_figs'
CONFIG_KEY = 'app_figs'
SHARED_KEY = 'shared_figs'
REPOSITORY_KEY = "repositories"
IMPORTS_KEY = 'import'
OPTIONAL_NAMESPACE = 'twig'
REPL_FROM_KEY = 'replicate_from'
SOURCE_NS_KEY = 'source_twig'
PARAMETERS_KEY = 'parameters'
SERVICE_KEY = 'service'
PLUGIN_KEY = 'plugins'

# Config paths
PS_FIGGY_ACCOUNTS_PREFIX = '/figgy/accounts/'
PS_FIGGY_DEFAULT_SERVICE_NS_PATH = '/figgy/defaults/service-namespace'

# Replication Types:
repl_types = [REPL_TYPE_APP, REPL_TYPE_MERGE]

# File names / paths
HOME = str(Path.home())
DECRYPTER_S3_PATH_PREFIX = f'figgy/decrypt/'
AWS_CREDENTIALS_FILE_PATH = f'{HOME}/.aws/credentials'
AWS_CONFIG_FILE_PATH = f'{HOME}/.aws/config'
CACHE_OTHER_DIR = f'{HOME}/.figgy/cache/other'
DEFAULT_INSTALL_PATH = '/usr/local/bin/figgy'
ERROR_LOG_DIR = f'{HOME}/.figgy/errors'
CONFIG_OVERRIDE_FILE_PATH = f'{HOME}/.figgy/config'
DEFAULTS_FILE_CACHE_PATH = f'{CACHE_OTHER_DIR}/defaults.json'
CONFIG_CACHE_FILE_PATH = f'{CACHE_OTHER_DIR}/config-cache.json'
STS_SESSION_CACHE_PATH = f"{HOME}/.figgy/vault/sts/sessions"
SAML_SESSION_CACHE_PATH = f"{HOME}/.figgy/vault/sso/saml"
OKTA_SESSION_CACHE_PATH = f"{HOME}/.figgy/cache/okta/session"
GOOGLE_SESSION_CACHE_PATH = f"{HOME}/.figgy/cache/google/session"

# Defaults file keys
DEFAULTS_ROLE_KEY = 'role'
DEFAULTS_ENV_KEY = 'default_env'
DEFAULTS_COLORS_ENABLED_KEY = 'colors'
DEFAULTS_USER_KEY = 'user'
DEFAULTS_PROVIDER_KEY = 'provider'
DEFAULTS_PROFILE_KEY = 'profile'
DEFAULTS_REGION_KEY = 'region'
MFA_SERIAL_KEY = 'mfa_serial'
DEFAULTS_KEY = 'defaults'

# Cache File keys
OKTA_SESSION_TOKEN_CACHE_KEY = 'session_token'
OKTA_SESSION_ID_CACHE_KEY = 'session_id'

# Plaform Constants
LINUX = "Linux"
MAC = "Darwin"
WINDOWS = "Windows"
ROOT_USER = "root"

# Build configs
OVERRIDE_KEYRING_ENV_VAR = "OVERRIDE_KEYRING"
ONE_WEEK_SECONDS = 60 * 60 * 24 * 7

# Figgy Sandbox
SANDBOX_ROLES = ['dev', 'devops', 'sre', 'data', 'dba']
GET_SANDBOX_CREDS_URL = "https://q39v8f3u13.execute-api.us-east-1.amazonaws.com/sandbox-bastion/v1/get-credentials"
FIGGY_SANDBOX_REGION = 'us-east-1'
FIGGY_SANDBOX_PROFILE = 'figgy-sandbox'

# Guaranteed Namespaces
shared_ns = '/shared'
figgy_ns = '/figgy'

# PS PATHS:
ACCOUNT_ID_PATH = f'{figgy_ns}/account_id'

# Vault
FIGGY_VAULT_FILES = [OKTA_SESSION_CACHE_PATH, GOOGLE_SESSION_CACHE_PATH, STS_SESSION_CACHE_PATH, SAML_SESSION_CACHE_PATH]