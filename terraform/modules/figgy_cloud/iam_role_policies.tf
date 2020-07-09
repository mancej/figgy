

# Policy created by
resource "aws_iam_policy" "figgy_access_policy" {
  count       = length(var.cfgs.role_types)
  name        = "figgy_${var.cfgs.role_types[count.index]}_access"
  description = "Dynamic figgy access policy for role: ${var.cfgs.role_types[count.index]}"
  policy      = data.aws_iam_policy_document.dynamic_policy[count.index].json
}



# Dynamically assembled policy based on configure_figgy.tf locals configurations
data "aws_iam_policy_document" "dynamic_policy" {
  count = length(var.cfgs.role_types)
  statement {
    sid = "KmsDecryptPermissions"
    actions = [
      "kms:DescribeKey",
      "kms:Decrypt"
    ]
    resources = [
      # Looks up the keys the role has access to, then looks up the ARN from the provisioned key for that type
      for key_name in var.cfgs.role_to_kms_access[var.cfgs.role_types[count.index]] :
      aws_kms_key.encryption_key[index(var.cfgs.encryption_keys, key_name)].arn
    ]
  }

  statement {
    sid     = "KmsEncryptPermissions"
    actions = ["kms:Encrypt"]
    resources = [
      # Looks up the keys the role has access to, then looks up the ARN from the provisioned key for that type
      for key_name in var.cfgs.role_to_kms_access[var.cfgs.role_types[count.index]] :
      aws_kms_key.encryption_key[index(var.cfgs.encryption_keys, key_name)].arn
    ]
  }

  statement {
    sid       = "ListKeys"
    actions   = ["kms:ListKeys"]
    resources = ["*"]
  }

  statement {
    sid = "ParameterStorePermissions"
    actions = [
      "ssm:DeleteParameter",
      "ssm:DeleteParameters",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath",
      "ssm:PutParameter",
      "ssm:AddTagsToResource"
    ]

    # EVERYONE gets access to /shared, it is our global namespace.
    resources = concat([
      for ns in var.cfgs.role_to_ns_access[var.cfgs.role_types[count.index]] :
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter${ns}/*"
      ], [
      for ns in var.cfgs.global_read_namespaces :
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter${ns}/*"
      ]
    )
  }

  statement {
    sid       = "PSDescribe"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  statement {
    sid = "ConfigReplAccess"
    actions = [
      "dynamodb:Get*",
      "dynamodb:List*",
      "dynamodb:Put*",
      "dynamodb:Delete*",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "dynamodb:UpdateTimeToLive"
    ]
    resources = [aws_dynamodb_table.config_replication.arn]
  }

  statement {
    sid    = "DenySpecialConfigs"
    effect = "Deny"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/figgy/integrations/*",
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/admin/*"
    ]
  }

  statement {
    sid = "ReadFiggyDDBTables"
    actions = [
      "dynamodb:Get*",
      "dynamodb:List*",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]

    resources = [
      aws_dynamodb_table.config_replication.arn,
      aws_dynamodb_table.config_auditor.arn,
      aws_dynamodb_table.config_cache.arn
    ]
  }

  # Provide replication key access to appropriate environments
  dynamic "statement" {
    for_each = contains(var.cfgs.replication_key_access_envs, var.run_env) ? [true] : []
    content {
      sid = "KmsReplicationKeyAccess"
      actions = [
        "kms:DescribeKey",
        "kms:Decrypt"
      ]
      resources = [aws_kms_key.replication_key.arn]
    }
  }

}