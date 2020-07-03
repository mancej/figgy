variable "name" {
  description = "The unique name of the role"
}

variable "mfa" {
  description = "Whether to require mfa to use this role"
  default     = false
}

variable "max_session_duration" {
  description = "Max session duration in seconds for this assumed role. Default: 12 hours"
  default     = "43200"
}

variable "account_id" {
  description = "Account id to enable role assumption for"
}

variable "saml_provider" {
  description = "ARN of saml provider configured for SSO integration."
}