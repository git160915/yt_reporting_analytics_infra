include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id               = "mock-vpc-id",
    private_subnet_id    = "mock-private-subnet-id",
    responsible_subnet_id = "mock-responsible-subnet-id"
  }
}

terraform {
  source = "../../../../modules/ssm"
}

# Use dependency outputs if needed; otherwise, the SSM module should not try to manage VPC resources.
inputs = {
  # For example, if you need the VPC id for tagging:
  vpc_id = dependency.vpc.outputs.vpc_id
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-state-bucket-yt-rpt-ana-infra"
    key            = "dev/ssm.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
