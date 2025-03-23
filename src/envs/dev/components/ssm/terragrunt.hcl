include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  region = get_env("AWS_REGION", "ap-southeast-2")
  environment = "dev"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id               = "mock-vpc-id",
    private_subnet_id    = "mock-private-subnet-id",
    responsible_subnet_id = "mock-responsible-subnet-id",
  }
}

terraform {
  source = "../../../../modules/ssm"
}

# Use dependency outputs if needed; otherwise, the SSM module should not try to manage VPC resources.
inputs = {
  # For example, if you need the VPC id for tagging:
  vpc_id = dependency.vpc.outputs.vpc_id
  ec2_ssm_role_name = "${local.environment}_ec2_ssm_role_name"
  ec2_ssm_instance_profile_name = "${local.environment}_ec2_ssm_instance_profile_name"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-state-bucket-yt-rpt-ana-infra"
    key            = "${local.environment}/ssm.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
