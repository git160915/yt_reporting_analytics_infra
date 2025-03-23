include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  region = get_env("AWS_REGION", "ap-southeast-2")
  environment = "integration"
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  cidr_block  = "10.0.0.0/16"
  vpc_name    = "${local.environment}-vpc"
  subnet_name = "${local.environment}-subnet"
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
