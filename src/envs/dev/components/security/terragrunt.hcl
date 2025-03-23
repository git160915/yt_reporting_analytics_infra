include {
  path = find_in_parent_folders()
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
  vpc_id = dependency.vpc.outputs.vpc_id
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-state-bucket-yt-rpt-ana-infra"
    key            = "dev/security.tfstate"  # Unique key for security state
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

