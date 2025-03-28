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
    responsible_subnet_id = "mock-responsible-subnet-id"
  }
}

dependency "security" {
  config_path = "../security"
  mock_outputs = {
    sg_id = "mock-sg-id"
  }
}

dependency "ssm" {
  config_path = "../ssm"
  mock_outputs = {
    ssm_instance_profile = "mock-ssm-instance-profile"
  }
}

terraform {
  source = "../../../../modules/responsible"
}

dependencies {
  paths = [
    "../vpc",
    "../security",
    "../ssm"
  ]
}

inputs = {
  # ami_id                = "ami-0c02fb55956c7d316"
  environment           = local.environment
  instance_type         = "t2.micro"
  responsible_subnet_id = dependency.vpc.outputs.responsible_subnet_id
  security_group_id     = dependency.security.outputs.sg_id
  instance_profile_name = dependency.ssm.outputs.ssm_instance_profile
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-state-bucket-yt-rpt-ana-infra"
    key            = "${local.environment}/responsible.tfstate"  # Unique key for responsible state
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}