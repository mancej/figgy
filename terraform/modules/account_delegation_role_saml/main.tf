resource "aws_iam_role" "role" {
  name                 = var.name
  assume_role_policy   = data.aws_iam_policy_document.role_policy.json
  max_session_duration = var.max_session_duration
}
