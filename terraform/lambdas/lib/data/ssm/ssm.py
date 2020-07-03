from botocore.exceptions import ClientError
from typing import Dict, List, Set

SSM_SECURE_STRING = "SecureString"


class SsmDao:
    def __init__(self, boto_ssm_client):
        self._ssm = boto_ssm_client

    def get_all_param_names(self, prefixes: List[str], option: str = 'Recursive', page: str = None) -> Set[str]:
        params = self.get_all_parameters(prefixes, option, page)
        return set([param['Name'] for param in params])

    def get_all_parameters(self, prefixes: List[str], option: str = 'Recursive', page: str = None) -> List[dict]:
        """
        Returns all parameters under prefix. Automatically pages recursively then returns full result set
        Args:
            prefixes: List of prefixes to query. E.G. [ '/shared', '/data', '/app' ]
            existing_params: Used in recursive calls to build a total result set
            page: Used in recursive calls if more pages exist.
            option: Must be 'Recursive' or 'OneLevel' - Indiates # of levels below the prefix to recurse.
        Returns: List[dict] -> Parameter details as returned from AWS API
        """
        filters = {
                      'Key': 'Path',
                      'Option': f'{option}',
                      'Values': prefixes
                  },
        total_params = []
        if page:
            params = self._ssm.describe_parameters(ParameterFilters=filters, NextToken=page,
                                                   MaxResults=50)
        else:
            params = self._ssm.describe_parameters(ParameterFilters=filters, MaxResults=50)

        total_params = total_params + params['Parameters']

        if params and 'NextToken' in params:
            total_params = total_params + self.get_all_parameters(prefixes, option=option, page=params['NextToken'])

        return total_params

    def delete_parameter(self, key) -> None:
        response = self._ssm.delete_parameter(Name=key)
        assert response and response['ResponseMetadata'] and response['ResponseMetadata']['HTTPStatusCode'] \
               and response['ResponseMetadata']['HTTPStatusCode'] == 200, \
            f"Error deleting key: [{key}] from PS. Please try again."

    def get_parameter(self, key) -> Dict:
        try:
            return self._ssm.get_parameter(Name=key, WithDecryption=True)
        except ClientError:
            return None

    def get_parameter_value(self, key) -> str:
        try:
            parameter = self._ssm.get_parameter(Name=key, WithDecryption=True)
            return parameter['Parameter']['Value']
        except ClientError:
            return None

    def set_parameter(self, key, value, desc, type, key_id=None) -> None:
        if key_id and type == SSM_SECURE_STRING:
            self._ssm.put_parameter(
                Name=key,
                Description=desc,
                Value=value,
                Overwrite=True,
                Type=type,
                KeyId=key_id
            )
        else:
            self._ssm.put_parameter(
                Name=key,
                Description=desc,
                Value=value,
                Overwrite=True,
                Type=type
            )
