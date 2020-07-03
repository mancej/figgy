module "replication_syncer" {
  source = "./modules/figgy_lambda"
  deploy_bucket = local.lambda_bucket_id
  description = "Incrementally synchronizes the replication across all parameters in case something gets out-of-wack"
  handler = "functions/replication_syncer.handle"
  lambda_name = "figgy-replication-syncer"
  lambda_timeout = 300
  policies = [aws_iam_policy.config_replication.arn, aws_iam_policy.lambda_default.arn, aws_iam_policy.lambda_read_configs.arn]
  zip_path = data.archive_file.figgy.output_path
  layers = [local.aws_sdk_layer_map[var.region]]
  cw_lambda_log_retention = var.figgy_cw_log_retention
}

module "replication_syncer_trigger" {
  source = "./modules/triggers/cron_trigger"
  lambda_name = module.replication_syncer.name
  lambda_arn = module.replication_syncer.arn
  schedule_expression = "rate(30 minutes)"
}
