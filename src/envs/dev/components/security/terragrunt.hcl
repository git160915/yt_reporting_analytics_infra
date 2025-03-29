include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  region      = local.env_vars.locals.region
  environment = local.env_vars.locals.environment
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "mock-vpc-id"
  }
}

terraform {
  source = "../../../../modules/security"
}

dependencies {
  paths = ["../vpc"]
}

inputs = {
  environment         = local.environment
  vpc_id              = dependency.vpc.outputs.vpc_id
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-state-bucket-yt-rpt-ana-infra"
    key            = "${local.environment}/security.tfstate"  # Unique key for security state
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

