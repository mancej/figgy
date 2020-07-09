
output "saml_provider_arn" {
  value = var.cfgs.enable_sso ? aws_iam_saml_provider.provider.*.arn : ["sso-disabled"]
}