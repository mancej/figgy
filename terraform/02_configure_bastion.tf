# THIS IS OPTIONAL. Only configure this if you are using bastion-account-based authentication and _not_ SSO authentication.

locals {
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
    "jordan.devops": ["devops", "dev", "dba", "sre", "data"]
    "jordan.dba": ["dba"]
    "jordan.sre": ["sre"]
    "jordan.data": ["dba", "data"]
    "jordan.dev": ["dev"]
  })
}


