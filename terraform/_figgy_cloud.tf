# Provisions figgy_cloud from the module - beware if you mess with this!
module "figgy_cloud" {
  source = "./modules/figgy_cloud"
  aws_account_id = var.aws_account_id
  deploy_bucket = var.deploy_bucket
  region = var.region
  run_env = var.run_env
  cfgs = merge(local.cfgs, local.bastion_cfgs, local.other_cfgs)
  extra_auth_types = var.extra_auth_types
  figgy_cw_log_retention = var.figgy_cw_log_retention
  max_session_duration = var.max_session_duration
  notify_deletes = var.notify_deletes
  webhook_url = var.webhook_url
  sandbox_deploy = var.sandbox_deploy
}