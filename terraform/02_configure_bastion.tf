# THIS IS OPTIONAL. Only configure this if you are using bastion-account-based authentication and _not_ SSO authentication.

locals {
  bastion_cfgs = {
      # Bastion account #. Set to your bastion account # if you are leveraging bastion based authentication. Otherwise ignore.
      # If `enable_sso = true` then ignore this.
      bastion_account_number = "513912394837"


      # MFA Enabled - "true/false" - Require MFA for authentication for bastion based auth? For SSO users MFA
      # is managed by your SSO provider. This is only for `bastion` MFA enforcement.
      # The CLI supports MFA for SSO / Bastion auth types.
      mfa_enabled = false

      # Please provide a mapping from all AWS "environments" to their respective account Ids
      # Format: "env" -> "account_id" (THESE MUST MAP to the var.run_env values you're using in your variables files)
      associated_accounts = tomap({
        "dev" : "880864869599",
        "qa" :  "024997347884",
        "stage": "363048742166",
        "prod" : "893170717001",
        "bastion" : "513912394837"
      })

      # Here, do a mapping of each user and their specified role(s)
      # These will be dynamically provisioned and configured for cross-account role authorizations
      bastion_users = tomap({
        "jordan.devops": ["devops", "dev", "dba", "sre", "data", "admin"]
        "jordan.dba": ["dba"]
        "jordan.sre": ["sre"]
        "jordan.data": ["dba", "data"]
        "jordan.dev": ["dev"]
      })
  }
}


