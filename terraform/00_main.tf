## This Multi Environment terraform project contains app specific iam policies / roles that will be used
## across multiple different apps and multiple environments. For roles / policies specific to a single application,
## include it in the app configuration itself.

# TODO: You must configure this to point the appropriate backend of your choosing.
# TODO: You may use S3 / Terraform Cloud (recommended) / Local / etc.
# TODO: Docs: https://www.terraform.io/docs/backends/index.html
terraform {
  required_version = ">=0.12.0"

  backend "remote" {
    hostname = "app.terraform.io"
    organization = "figgy"

    workspaces {
      prefix = "figgy-"
    }
  }
}

# TODO: You will need to configure this to point to YOUR environment. Use profiles, role assumption, whatever makes
# TODO: sense for your terraform environment. Docs: https://www.terraform.io/docs/providers/aws/index.html
provider "aws" {
  version = ">= 2.0.0"
  region = var.region

  assume_role {
    ## Todo: Update this to your own role, or remove this block and provide credentials to
    ## Terraform some other way.
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/figgy-admin"
  }
}

data "aws_caller_identity" "current" {}