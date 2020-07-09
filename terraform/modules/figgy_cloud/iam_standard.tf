## Only used for "Figgy Standard" deployments (NOT RECOMMENDED)

resource "aws_iam_group" "figgy_groups" {
  count = var.cfgs.standard_install ? length(var.cfgs.role_types) : 0
  name  = "figgy-${var.cfgs.role_types[count.index]}"
  path  = "/figgy/"
}

resource "aws_iam_group_policy_attachment" "figgy_ssm_access" {
  count      = var.cfgs.standard_install ? length(var.cfgs.role_types) : 0
  group      = aws_iam_group.figgy_groups[count.index].name
  policy_arn = aws_iam_policy.figgy_access_policy[count.index].arn
}