import logging
import re

from config import *
from botocore.exceptions import ClientError
from npyscreen import Form, MultiLineEdit, NPSApp, BoxTitle
from prompt_toolkit import prompt
from prompt_toolkit.completion import WordCompleter

from commands.config_context import ConfigContext
from commands.types.config import ConfigCommand
from data.dao.ssm import SsmDao
from svcs.observability.usage_tracker import UsageTracker
from svcs.observability.version_tracker import VersionTracker

log = logging.getLogger(__name__)


class MultiLineInput(BoxTitle):
    _contained_widget = MultiLineEdit


class EditApp(NPSApp):
    def __init__(self, name: str, value: str, description: str):
        self.name = name
        self.value = value if value else ''
        self.description = description if description else ''
        self.value_box = None
        self.description_box = None

    def main(self):
        edit_form = Form()
        self.value_box = edit_form.add(MultiLineInput, value=self.value, name=f'Input value for: {self.name}',
                                       max_height=12)
        self.description_box = edit_form.add(MultiLineInput, value=self.description, name="Optional Description: ",
                                             max_height=12)
        print(f"Value box: {self.value_box} - {self.description_box}")
        edit_form.edit()


class Edit(ConfigCommand):

    def __init__(self, ssm_init: SsmDao, colors_enabled: bool, config_context: ConfigContext,
                 config_completer: WordCompleter):
        super().__init__(edit, colors_enabled, config_context)
        self._ssm = ssm_init
        self._utils = Utils(colors_enabled)
        self._config_completer = config_completer
        self._select_name = [
            ('class:', 'Please input a PS Name: ')
        ]

    def edit(self) -> None:
        """
        Allows a user to define a PS name and add or edit a parameter at that location. Uses NPYscreen editor.
        """

        key = prompt(self._select_name, completer=self._config_completer)
        self._utils.validate_ps_name(key)

        value, desc = self._ssm.get_parameter_with_description(key)
        edit_app = EditApp(key, value, desc)
        edit_app.run()

        value, desc = edit_app.value_box.value, edit_app.description_box.value
        log.info(f"Edited value: {value} - description: {desc}")

        if re.match(f'^{shared_ns}/.*$', key) is None:
            selection = prompt(is_secret, completer=WordCompleter(['Y', 'N'])).strip().lower()
            selection = selection if selection != '' else 'n'
        else:
            selection = "n"

        parameter_type = SSM_STRING if selection.lower() == "n" else SSM_SECURE_STRING
        key_id = None if parameter_type == SSM_STRING else \
            self._ssm.get_parameter(self._utils.get_kms_key(self.role))

        if not self._utils.is_valid_input(key, f"Parameter name", True) \
                or not self._utils.is_valid_selection(selection, True) \
                or not self._utils.is_valid_input(value, key, True):
            self._utils.error_exit("Invalid input detected, please resolve the issue and retry.")

        try:
                self._ssm.set_parameter(key, value, desc, parameter_type, key_id=key_id)
        except ClientError as e:
            if "AccessDeniedException" == e.response['Error']['Code']:
                print(
                    f"\n\nYou do not have permissions to put a new config value at the path: {self.c.fg_bl}{key}{self.c.rs}")
                print(
                    f"Developers may add keys under the following namespaces: {self.c.fg_bl}{DEV_PS_WRITE_NS}{self.c.rs}")
                print(f"{self.c.fg_rd}Error message: {e.response['Error']['Message']}{self.c.rs}")
            else:
                print(
                    f"{self.c.fg_rd}Exception caught attempting to add config: {e}{self.c.rs}")

    @VersionTracker.notify_user
    @UsageTracker.track_command_usage
    def execute(self):
        self.edit()