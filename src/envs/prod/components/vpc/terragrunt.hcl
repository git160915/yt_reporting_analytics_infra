include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  region      = local.env_vars.locals.region
  environment = local.env_vars.locals.environment
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  cidr_block  = "10.0.0.0/16"
  environment = local.environment
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-state-bucket-yt-rpt-ana-infra"
    key            = "${local.environment}/vpc.tfstate"  # Unique key for VPC state
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
