resource "aws_dynamodb_table" "config_replication" {
  name           = "figgy-config-replication"
  hash_key       = "destination"
  range_key      = "run_env"
  billing_mode = "PAY_PER_REQUEST"
  stream_enabled = "true"
  stream_view_type = "KEYS_ONLY"

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "destination"
    type = "S"
  }

  attribute {
    name = "run_env"
    type = "S"
  }

  tags = {
    Name        = "figgy-config-replication"
    Environment = var.run_env
    owner = "devops"
    application = "figgy"
    created_by = "figgy"
  }
}

resource "aws_dynamodb_table" "config_auditor" {
  name           = "figgy-config-auditor"
  hash_key       = "parameter_name"
  range_key      = "time"
  billing_mode = "PAY_PER_REQUEST"

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "parameter_name"
    type = "S"
  }

  attribute {
    name = "time"
    type = "N"
  }

  tags = {
    Name        = "figgy-config-auditor"
    Environment = var.run_env
    owner = "devops"
    application = "figgy"
    created_by = "figgy"
  }
}

resource "aws_dynamodb_table" "config_cache" {
  name           = "figgy-config-cache"
  hash_key       = "parameter_name"
  range_key      = "last_updated"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "parameter_name"
    type = "S"
  }

  attribute {
    name = "last_updated"
    type = "N"
  }

  tags = {
    Name        = "figgy-config-cache"
    Environment = var.run_env
    owner = "devops"
    application = "figgy"
    created_by = "figgy"
  }
}
