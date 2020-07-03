## Please fill out this file to custom-configure your figgy deployment to meet your needs

## IMPORTANT:
## If you have already provisioned figgy, rearranging values under `encryption_keys` or `user_types` could require
## these resources to be removed/recreated which would probably be a pretty bad thing~!
locals {

  # If you want figgy to create its own S3 bucket, set this to true, then specify the `var.deploy_bucket`
  # with the appropriate deployment bucket name variable. This bucket is used to store figgy deployment artifacts.
  create_deploy_bucket = true

  # Cloudtrail logging is required by Figgy we can turn it on for you, or you can enable it on your own.
  # If you don't have it enabled, or want to enable it yourself, set this to false.
  configure_cloudtrail = true

  # How many unique roles will figgy users need? Each of these types should map to a particular figgy user story.
  role_types = ["devops", "data", "dba", "sre", "dev"]

  # Encryption keys to allow certain roles to use to encrypt and decrypt secrets stored with figgy.
  # You will map access below
  encryption_keys = ["app", "devops", "data"]

  # List of namespaces at the root level of your parameter store namespace. Figgy (and its users)
  # will ONLY have access to _AT MOST_ configs under these namespaces.
  # ** /shared is required by figgy, all otheres are optional
  root_namespaces = ["/shared", "/app", "/data", "/devops", "/sre", "/dba"]

  # This namespace is where _all_ service specific configurations will be stored. Must be one of the above listed
  # namespaces. I recommend keeping /app
  service_namespace = "/app"

  # Configure access permissions by mapping your role_types to namespace access levels. Be careful to ensure you
  # don't have any typos here. These must match the above `role_types` and `root_namespaces` configurations
  # Format: Map[str:List[str]], or more specifically Map[role_type:List[namespace]]
  role_to_ns_access = {
    "devops" = ["/app", "/devops", "/data", "/sre", "/shared"],
    "data" = ["/app", "/data", "/shared"],
    "sre" = ["/sre", "/app", "/data", "/shared"],
    "dev" = ["/app", "/shared"],
    "dba" = ["/dba", "/app", "/shared"]
  }

  # Map role type access to various encryption keys provisioned by figgy.
  # Format: Map[str:List[str]], specifically Map[role_type:List[encryption_key]]
  role_to_kms_access = {
    "devops" = [ "devops", "app", "data" ]
    "data" = [ "data", "app" ]
    "dba" = [ "data", "app" ]
    "sre" = [ "app" ]
    "dev" = [ "app"]
  }

  # Options: "okta", "google", "bastion"
  auth_type = "bastion"

  # Bastion account #. Set to your bastion account # if you are leveraging bastion based authentication. Otherwise ignore.
  # If `enable_sso = true` then ignore this.
  bastion_account_number = "513912394837"

  # Environments with replication key access. This will give all user types access to the figgy replication key.
  # and enable users to run services locally and decrypt secrets shared with their application. Ideal for
  # local development. More details: https://www.figgy.dev/docs/advanced/confidentiality.html
  replication_key_access_envs = ["dev"]

  # MFA Enabled - "true/false" - Require MFA for authentication for bastion based auth? For SSO users MFA
  # is managed by your SSO provider. This is only for `bastion` MFA enforcement. The CLI supports MFA for SSO / Bastion auth types.
  mfa_enabled = false

  # This is optional. If you'd like to receive notifications for configuration events, input a webhook url here.
  # You may enter it here, or instead update
  slack_webhook_url = var.webhook_url
}