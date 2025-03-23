include {
  path = find_in_parent_folders()
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
  private_subnet_id     = dependency.vpc.outputs.private_subnet_id
  security_group_id     = dependency.security.outputs.sg_id
  instance_profile_name = dependency.ssm.outputs.ssm_instance_profile
}
