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
    private_subnet_id    = "mock-private-subnet-id"
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
  source = "../../../../modules/ec2"
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
  instance_type         = "t2.micro"
  instance_name         = "${local.environment}-PythonEC2Instance"
  private_subnet_id     = dependency.vpc.outputs.private_subnet_id
  security_group_id     = dependency.security.outputs.sg_id
  instance_profile_name = dependency.ssm.outputs.ssm_instance_profile
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-state-bucket-yt-rpt-ana-infra"
    key            = "${local.environment}/python_ec2.tfstate"  # Unique key for python_ec2 state
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}