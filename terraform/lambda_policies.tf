# Default lambda policy
resource "aws_iam_policy" "lambda_default" {
  name = "figgy-default-lambda"
  path = "/"
  description = "Default IAM policy for figgy lambda. Provides basic Lambda access, such as writing logs to CW."
  policy = data.aws_iam_policy_document.lambda_default.json
}

data "aws_iam_policy_document" "lambda_default" {
  statement {
    sid = "DefaultLambdaAccess"
    actions = [
        "cloudwatch:Describe*",
        "cloudwatch:Get*",
        "cloudwatch:List*",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:TestMetricFilter",
    ]

    resources = ["*"]
  }
}

# Config Auditor Lambda
resource "aws_iam_policy" "config_auditor" {
  name = "config-auditor"
  path = "/"
  description = "IAM policy for figgy confg_auditor lambda"
  policy = data.aws_iam_policy_document.config_auditor_document.json
}

data "aws_iam_policy_document" "config_auditor_document" {
  statement {
    sid = "AuditTableDDBAccess"
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
    resources = [aws_dynamodb_table.config_auditor.arn]
  }

  statement {
    sid = "AuditorPSRead"
    actions =[
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:List*",
      "ssm:DescribeParameters"
    ]
    resources = [ "*" ]
  }
}

# Config cache manager / syncer lambdas
resource "aws_iam_policy" "config_cache_manager" {
  name = "config-cache-manager"
  path = "/"
  description = "IAM policy for figgy config_cache_manager/syncer lambdas"
  policy = data.aws_iam_policy_document.config_cache_manager_document.json
}

data "aws_iam_policy_document" "config_cache_manager_document" {
  statement {
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
    resources = [aws_dynamodb_table.config_cache.arn]
  }

  statement {
    sid = "SSMDescribe"
    actions = ["ssm:DescribeParameters"]
    resources = ["*"]
  }
}

# Replication lambdas policy
resource "aws_iam_policy" "config_replication" {
  name = "config-replication"
  path = "/"
  description = "IAM policy for figgy replication management lambdas"
  policy = data.aws_iam_policy_document.config_replication_document.json
}

data "aws_iam_policy_document" "config_replication_document" {
  statement {
    sid = "ReplicationTableFullAccess"
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
    resources = [ aws_dynamodb_table.config_replication.arn ]
  }

  statement {
    sid = "ReplicationTableStreamRead"
    actions = [
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams",
      "dynamodb:DescribeStream"
    ]
    resources = [ aws_dynamodb_table.config_replication.stream_arn ]
  }

  statement {
    sid = "FiggyKMSAccess"
    actions = [
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:Encrypt"
    ]

    resources = concat([ for x in aws_kms_key.encryption_key: x.arn ], [aws_kms_key.replication_key.arn])
  }
  
  statement {
    sid = "KMSListKeys"
    actions = [ "kms:ListKeys"]
    resources = [ "*" ]
  }
  
  statement {
    sid = "FiggySSMAccess"
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
    resources = distinct(concat(
      [
        for x in local.root_namespaces:
          format("arn:aws:ssm:*:%s:parameter%s/*", data.aws_caller_identity.current.account_id, x)
      ],
      [
        for ns in local.global_read_namespaces:
          "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter${ns}/*"
      ]
    ))
  }

  statement {
    sid = "SSMDescribe"
    actions = ["ssm:DescribeParameters"]
    resources = ["*"]
  }
}


# Read configs under /figgy namespace
resource "aws_iam_policy" "lambda_read_configs" {
  name = "figgy-lambda-read-configs"
  path = "/"
  description = "IAM policy to enable figgy lambdas to read figgy-specific configurations"
  policy = data.aws_iam_policy_document.lambda_read_figgy_configs.json
}

data "aws_iam_policy_document" "lambda_read_figgy_configs" {
  statement {
    sid = "FiggySSMAccess"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = [ "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/figgy/*"]
  }

  statement {
      sid = "SSMDescribe"
      actions = [ "ssm:DescribeParameters" ]
      resources = [ "*" ]
    }

}