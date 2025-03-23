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
  vpc_id              = dependency.vpc.outputs.vpc_id
  security_group_name = "${local.environment}-ec2-private-sg"
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

