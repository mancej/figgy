# SSO SAML sts policy
data "aws_iam_policy_document" "role_policy" {
  statement {
    effect = "Allow"

    principals {
      identifiers = [var.saml_provider]
      type        = "Federated"
    }

    actions = [
      "sts:AssumeRoleWithSAML",
    ]

    condition {
      test     = "StringEquals"
      variable = "SAML:aud"
      values   = ["https://signin.aws.amazon.com/saml"]
    }
  }
}
