locals {
  region      = get_env("AWS_REGION", "ap-southeast-2")
  environment = "dev"

  tags = {
    Environment = local.environment
    Owner       = "Platform Team"
  }
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-state-bucket-yt-rpt-ana-infra"
    key            = "${local.environment}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
