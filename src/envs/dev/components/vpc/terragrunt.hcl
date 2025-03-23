include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  cidr_block = "10.0.0.0/16"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-state-bucket-yt-rpt-ana-infra"
    key            = "dev/vpc.tfstate"  # Unique key for VPC state
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
