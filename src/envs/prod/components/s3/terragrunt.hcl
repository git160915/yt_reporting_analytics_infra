include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  region      = local.env_vars.locals.region
  environment = local.env_vars.locals.environment
}

terraform {
  source = "../../../../modules/s3"
}

inputs = {
  buckets = {
    "${local.environment}-myapp-bucket1" = {
      versioning_enabled = true
    },
    "${local.environment}-myapp-bucket2" = {
      versioning_enabled = false
    }
  }
}
