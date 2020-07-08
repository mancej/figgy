module "dynamo_stream_replicator" {
  source = "./modules/figgy_lambda"
  deploy_bucket = local.lambda_bucket_id
  description = "Instantly replicates source -> destination configuration changes when someone uses figgy to alter replication mappings."
  handler = "functions/dynamo_stream_replicator.handle"
  lambda_name = "figgy-dynamo-stream-replicator"
  lambda_timeout = 300
  policies = [aws_iam_policy.config_replication.arn, aws_iam_policy.lambda_default.arn, aws_iam_policy.lambda_read_configs.arn]
  zip_path = data.archive_file.figgy.output_path
  layers = [local.aws_sdk_layer_map[var.region]]
  cw_lambda_log_retention = var.figgy_cw_log_retention
  sns_alarm_topic = aws_sns_topic.figgy_alarms.arn
}

module "dynamo_stream_replicator_trigger" {
  source = "./modules/triggers/ddb_trigger"
  lambda_name = module.dynamo_stream_replicator.name
  dynamo_stream_arn = aws_dynamodb_table.config_replication.stream_arn
}
