variable "lambda_name" {
  description = "Figgy lambda to be deployed"
}

variable "lambda_timeout" {
  description = "Timeout in seconds for this lambda"
}

variable "deploy_bucket" {
  description = "Bucket name that this lambda is deployed to."
}

variable "handler" {
  description = "Path to handler method."
}

variable "description" {
  description = "Description to be attached to this lambda in its AWS deployment"
}

variable "policies" {
  description = "List of policy ARNs to attach to this lambda"
}

variable "zip_path" {
  description = "Path to the Figgy zip artifact."
}

variable "concurrent_executions" {
  description = "Max # of concurrent executions for this lambda"
  default = 1
}

variable "layers" {
  description = "Layers to attach to this lambda."
}

variable "cw_lambda_log_retention" {
  description = "# of days to keep figgy lambda logs in cloudwatch"
  default = 30
}

variable "sns_alarm_topic" {
  description = "ARN for SNS topic for triggered CloudWatch alarm notifications to."
}

variable "sha256" {
  description = "Sha256 of provided data archive"
}

variable "memory_size" {
  description = "Amount of memory to provision for this lambda"
  default = 128
}