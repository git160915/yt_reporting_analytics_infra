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
    vpc_id                = "mock-vpc-id"
    private_subnet_id     = "mock-private-subnet-id"
    responsible_subnet_id = "mock-responsible-subnet-id"
  }
}

dependency "security" {
  config_path = "../security"
  mock_outputs = {
    sg_id = "mock-sg-id"
  }
}

terraform {
  source = "../../../../modules/vpc_endpoints"
}

inputs = {
  environment         = local.environment
  vpc_id              = dependency.vpc.outputs.vpc_id       # from your VPC module dependency
  subnet_ids          = [dependency.vpc.outputs.private_subnet_id, dependency.vpc.outputs.responsible_subnet_id]  # a list of subnet IDs
  vpc_endpoint_sg_ids = [dependency.security.outputs.sg_id]  # Provide the security group IDs for the endpoints
  region              = local.region   # This comes from your common or environment configuration
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-state-bucket-yt-rpt-ana-infra"
    key            = "${local.environment}/vpc_endpoints.tfstate"  # Unique key for VPC state
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}