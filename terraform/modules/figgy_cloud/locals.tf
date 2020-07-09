locals {

  # The figgy sandbox allows role assumption by accountId and by RoleId. This is unique to the figgy sandbox.
  principals = var.sandbox_deploy ? var.cfgs.sandbox_principals : var.cfgs.bastion_principal
  lambda_bucket = var.deploy_bucket
}

