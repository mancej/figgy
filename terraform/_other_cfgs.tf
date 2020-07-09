# You do not need to tweak anything in this file - Please do not touch unles you 100% know what you're doing!
locals {
  other_cfgs = {
    # This links your version of Figgy Cloud to the FiggyCLI.
    version = "1.0.0"

    # Global read namespaces
    global_read_namespaces = [
      "/shared",
      "/figgy"]

    # Merged config based on user selections
    enable_sso = local.cfgs.auth_type == "okta" || local.cfgs.auth_type == "google"
    bastion_enabled = local.cfgs.auth_type == "bastion"
    standard_install = local.cfgs.auth_type == "standard"
    auth_types = concat([
      local.cfgs.auth_type], var.extra_auth_types)

    # sandbox_principals is only used in the figgy sandbox environment. This should never be true for you.
    sandbox_principals = [
      local.bastion_cfgs.bastion_account_number,
      "arn:aws:iam::${local.bastion_cfgs.bastion_account_number}:role/%%ROLE%%"]
    bastion_principal = [
      local.bastion_cfgs.bastion_account_number]

    # Todo: Later do an auto-pip install from local, then zip up dependencies, add as layer, then pass layer ARN into
    # Todo: the functions. (Wrap in a make command perhaps)
    aws_sdk_layer_map = {
      ap-northeast-1: "arn:aws:lambda:ap-northeast-1:249908578461:layer:AWSLambda-Python-AWS-SDK:4"
      us-east-1: "arn:aws:lambda:us-east-1:668099181075:layer:AWSLambda-Python-AWS-SDK:4"
      ap-southeast-1:    "arn:aws:lambda:ap-southeast-1:468957933125:layer:AWSLambda-Python-AWS-SDK:4"
      eu-west-1:    "arn:aws:lambda:eu-west-1:399891621064:layer:AWSLambda-Python-AWS-SDK:4"
      us-west-1:    "arn:aws:lambda:us-west-1:325793726646:layer:AWSLambda-Python-AWS-SDK:4"
      ap-east-1:    "arn:aws:lambda:ap-east-1:118857876118:layer:AWSLambda-Python-AWS-SDK:4"
      ap-northeast-2:    "arn:aws:lambda:ap-northeast-2:296580773974:layer:AWSLambda-Python-AWS-SDK:4"
      ap-northeast-3:    "arn:aws:lambda:ap-northeast-3:961244031340:layer:AWSLambda-Python-AWS-SDK:4"
      ap-south-1:    "arn:aws:lambda:ap-south-1:631267018583:layer:AWSLambda-Python-AWS-SDK:4"
      ap-southeast-2:    "arn:aws:lambda:ap-southeast-2:817496625479:layer:AWSLambda-Python-AWS-SDK:4"
      ca-central-1:    "arn:aws:lambda:ca-central-1:778625758767:layer:AWSLambda-Python-AWS-SDK:4"
      eu-central-1:    "arn:aws:lambda:eu-central-1:292169987271:layer:AWSLambda-Python-AWS-SDK:4"
      eu-north-1:    "arn:aws:lambda:eu-north-1:642425348156:layer:AWSLambda-Python-AWS-SDK:4"
      eu-west-2:    "arn:aws:lambda:eu-west-2:142628438157:layer:AWSLambda-Python-AWS-SDK:4"
      eu-west-3:    "arn:aws:lambda:eu-west-3:959311844005:layer:AWSLambda-Python-AWS-SDK:4"
      sa-east-1:    "arn:aws:lambda:sa-east-1:640010853179:layer:AWSLambda-Python-AWS-SDK:4"
      us-east-2:    "arn:aws:lambda:us-east-2:259788987135:layer:AWSLambda-Python-AWS-SDK:4"
      us-west-2:    "arn:aws:lambda:us-west-2:420165488524:layer:AWSLambda-Python-AWS-SDK:5"
      cn-north-1:    "arn:aws-cn:lambda:cn-north-1:683298794825:layer:AWSLambda-Python-AWS-SDK:4"
      cn-northwest-1:    "arn:aws-cn:lambda:cn-northwest-1:382066503313:layer:AWSLambda-Python-AWS-SDK:4"
      us-gov-west:    "arn:aws-us-gov:lambda:us-gov-west-1:556739011827:layer:AWSLambda-Python-AWS-SDK:4"
      us-gov-east:    "arn:aws-us-gov:lambda:us-gov-east-1:138526772879:layer:AWSLambda-Python-AWS-SDK:4"
    }
  }
}
