## Only used for "Figgy Standard" deployments (NOT RECOMMENDED)

resource "aws_iam_group" "figgy_groups" {
  count = local.standard_install ? length(local.role_types) : 0
  name = "figgy-${local.role_types[count.index]}"
  path = "/figgy/"
}

resource "aws_iam_group_policy_attachment" "figgy_ssm_access" {
  count = local.standard_install ? length(local.role_types) : 0
  group = aws_iam_group.figgy_groups[count.index].name
  policy_arn = aws_iam_policy.figgy_access_policy[count.index].arn
}