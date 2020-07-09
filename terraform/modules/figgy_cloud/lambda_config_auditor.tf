module "config_auditor" {
  source                  = "../figgy_lambda"
  deploy_bucket           = local.lambda_bucket
  description             = "Maintains the figgy audit database that is used for configuration restoration."
  handler                 = "functions/config_auditor.handle"
  lambda_name             = "figgy-config-auditor"
  lambda_timeout          = 60
  policies                = [aws_iam_policy.config_auditor.arn, aws_iam_policy.lambda_default.arn, aws_iam_policy.lambda_read_configs.arn]
  zip_path                = data.archive_file.figgy.output_path
  layers                  = [var.cfgs.aws_sdk_layer_map[var.region]]
  cw_lambda_log_retention = var.figgy_cw_log_retention
  sns_alarm_topic         = aws_sns_topic.figgy_alarms.arn
  sha256 = data.archive_file.figgy.output_base64sha256
}

module "config_auditor_trigger" {
  source           = "../triggers/cw_trigger"
  lambda_name      = module.config_auditor.name
  lambda_arn       = module.config_auditor.arn
  cw_event_pattern = <<PATTERN
{
  "source": [
    "aws.ssm"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "ssm.amazonaws.com"
    ],
    "eventName": [
      "PutParameter",
      "DeleteParameter",
      "DeleteParameters"
    ]
  }
}
PATTERN
}