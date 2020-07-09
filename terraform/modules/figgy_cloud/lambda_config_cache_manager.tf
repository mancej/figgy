module "config_cache_manager" {
  source                  = "../figgy_lambda"
  deploy_bucket           = var.deploy_bucket
  description             = "Manages a DDB cache of items that figgy uses to populate auto-complete for CLI users."
  handler                 = "functions/config_cache_manager.handle"
  lambda_name             = "figgy-config-cache-manager"
  lambda_timeout          = 60
  policies                = [aws_iam_policy.config_cache_manager.arn, aws_iam_policy.lambda_default.arn, aws_iam_policy.lambda_read_configs.arn]
  zip_path                = data.archive_file.figgy.output_path
  layers                  = [var.cfgs.aws_sdk_layer_map[var.region]]
  cw_lambda_log_retention = var.figgy_cw_log_retention
  sns_alarm_topic         = aws_sns_topic.figgy_alarms.arn
}

module "config_cache_manager_trigger" {
  source           = "../triggers/cw_trigger"
  lambda_name      = module.config_cache_manager.name
  lambda_arn       = module.config_cache_manager.arn
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