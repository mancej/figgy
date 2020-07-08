module "ssm_stream_replicator" {
  source = "./modules/figgy_lambda"
  deploy_bucket = local.lambda_bucket_id
  description = "Listens to the CW event stream for SSM events and triggers replication if replication sources are changed."
  handler = "functions/ssm_stream_replicator.handle"
  lambda_name = "figgy-ssm-stream-replicator"
  lambda_timeout = 60
  policies = [aws_iam_policy.config_replication.arn, aws_iam_policy.lambda_default.arn, aws_iam_policy.lambda_read_configs.arn]
  zip_path = data.archive_file.figgy.output_path
  layers = [local.aws_sdk_layer_map[var.region]]
  cw_lambda_log_retention = var.figgy_cw_log_retention
  sns_alarm_topic = aws_sns_topic.figgy_alarms.arn
}

module "ssm_stream_replicator_trigger" {
  source = "./modules/triggers/cw_trigger"
  lambda_name = module.ssm_stream_replicator.name
  lambda_arn = module.ssm_stream_replicator.arn
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