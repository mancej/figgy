
resource "aws_iam_role" "bastion_user_role" {
  count                = var.cfgs.bastion_enabled ? length(var.cfgs.role_types) : 0
  name                 = "figgy-${var.env_alias}-${var.cfgs.role_types[count.index]}"
  assume_role_policy   = var.cfgs.bastion_enabled ? data.aws_iam_policy_document.bastion_role_policy[count.index].json : ""
  max_session_duration = var.max_session_duration
}

# Role policy to allow cross-account assumption from bastion account
data "aws_iam_policy_document" "bastion_role_policy" {
  count = var.cfgs.bastion_enabled ? length(var.cfgs.role_types) : 0
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        for principal in local.principals :
        replace(principal, "%%ROLE%%", "figgy-${var.cfgs.role_types[count.index]}")
      ]
    }

    dynamic "condition" {
      for_each = var.cfgs.mfa_enabled ? [true] : []
      content {
        test     = "Bool"
        values   = [var.cfgs.mfa_enabled]
        variable = "aws:MultiFactorAuthPresent"
      }
    }
  }
}

resource "aws_iam_role_policy_attachment" "bastion_role_policy_attachment" {
  count      = var.cfgs.bastion_enabled ? length(var.cfgs.role_types) : 0
  role       = aws_iam_role.bastion_user_role[count.index].name
  policy_arn = aws_iam_policy.figgy_access_policy[count.index].arn
}

# Provision users and attach policies. Policies grant users to access `/figgy` PS namespace for general figgy config
# And to look up their own user. This is needed to look-up their own user-name from their local bastion credentials. yes
resource "aws_iam_user" "users" {
  count = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? length(var.cfgs.bastion_users) : 0
  name  = element(keys(var.cfgs.bastion_users), count.index)
  path  = "/figgy/"
}

resource "aws_iam_user_policy" "get_self" {
  count  = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? length(var.cfgs.bastion_users) : 0
  name   = "figgy-manage-self"
  policy = data.aws_iam_policy_document.manage_self[count.index].json
  user   = aws_iam_user.users[count.index].name
}

# Informed by: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_my-sec-creds-self-manage-mfa-only.html
# and https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_my-sec-creds-self-manage.html
data "aws_iam_policy_document" "manage_self" {
  count = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? length(var.cfgs.bastion_users) : 0
  statement {
    sid       = "GetSelf"
    actions   = ["iam:GetUser"]
    resources = [aws_iam_user.users[count.index].arn]
  }

  statement {
    sid = "AllowViewAccountInfo"
    actions = [
      "iam:AllowViewAccountInfo",
      "iam:GetAccountPasswordPolicy",
      "iam:GetAccountSummary"
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowManageOwnVirtualMFADevice"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice"
    ]
    resources = [
      aws_iam_user.users[count.index].arn,
      "arn:aws:iam::${var.aws_account_id}:mfa/${aws_iam_user.users[count.index].name}",
    ]
  }

  statement {
    sid = "AllowManageOwnUserMFA"
    actions = [
      "iam:DeactivateMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ResyncMFADevice"
    ]
    resources = [aws_iam_user.users[count.index].arn]
  }

  statement {
    sid = "AllowManageOwnAccessKeys"
    actions = [
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:ListAccessKeys",
      "iam:UpdateAccessKey"
    ]
    resources = [aws_iam_user.users[count.index].arn]
  }

  statement {
    sid = "AllowManageOwnPasswords"
    actions = [
      "iam:ChangePassword",
      "iam:GetUser"
    ]
    resources = [aws_iam_user.users[count.index].arn]
  }
}

# Create 1 group for each role-type and add mapped users to those groups.
# Also attach policies to each group that provides assume-role access into matching roles for that group.
resource "aws_iam_group" "groups" {
  count = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? length(var.cfgs.role_types) : 0
  name  = element(var.cfgs.role_types, count.index)
  path  = "/figgy/"
}

resource "aws_iam_user_group_membership" "user_memberships" {
  count = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? length(var.cfgs.bastion_users) : 0
  groups = [
    for role in var.cfgs.bastion_users[keys(var.cfgs.bastion_users)[count.index]] :
    aws_iam_group.groups[index(var.cfgs.role_types, role)].name
  ]
  user = aws_iam_user.users[count.index].name
}

resource "aws_iam_policy" "cross_account_policy" {
  count  = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? length(var.cfgs.role_types) : 0
  name   = "figgy-assume-${var.cfgs.role_types[count.index]}"
  policy = data.aws_iam_policy_document.cross_account_assume[count.index].json
}

resource "aws_iam_group_policy_attachment" "cross_account_assume_attachment" {
  count      = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? length(var.cfgs.role_types) : 0
  group      = aws_iam_group.groups[count.index].name
  policy_arn = aws_iam_policy.cross_account_policy[count.index].arn
}

data "aws_iam_policy_document" "cross_account_assume" {
  count = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? length(var.cfgs.role_types) : 0
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:aws:iam::*:role/figgy-*-${var.cfgs.role_types[count.index]}"
    ]
  }
}

resource "aws_iam_group_policy_attachment" "groups_read_figgy_configs" {
  count      = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? length(var.cfgs.role_types) : 0
  group      = aws_iam_group.groups[count.index].name
  policy_arn = aws_iam_policy.read_figgy_configs[0].arn
}
resource "aws_iam_group_policy_attachment" "groups_describe_params" {
  count      = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? length(var.cfgs.role_types) : 0
  group      = aws_iam_group.groups[count.index].name
  policy_arn = aws_iam_policy.describe_parameters[0].arn
}

resource "aws_iam_policy" "read_figgy_configs" {
  count  = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? 1 : 0
  name   = "figgy-get-figgy-configs"
  policy = data.aws_iam_policy_document.get_figgy_configs[0].json
}

resource "aws_iam_policy" "describe_parameters" {
  count  = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? 1 : 0
  name   = "figgy-describe-parameters"
  policy = data.aws_iam_policy_document.describe_parameters[0].json
}

data "aws_iam_policy_document" "get_figgy_configs" {
  count = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? 1 : 0
  statement {
    sid = "GetFiggyConfigs"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/figgy/*"
    ]
  }

  statement {
    sid    = "DenySpecialFigs"
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
}

# We cannot scope these to just the `/figgy` namespace or else we would. Unfortunately AWS does not allow
# limiting Describe calls to specific prefixes.
data "aws_iam_policy_document" "describe_parameters" {
  count = var.cfgs.bastion_enabled && var.cfgs.bastion_account_number == var.aws_account_id ? 1 : 0
  statement {
    sid = "DescribeParameters"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = [
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:*"
    ]
  }
}