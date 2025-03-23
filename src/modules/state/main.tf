resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name
  force_destroy = true

  tags = {
    Environment = var.environment
  }
}

/* resource "aws_s3_bucket_acl" "terraform_state_acl" {
  bucket = aws_s3_bucket.terraform_state.id
  acl    = "private"
}*/

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}
