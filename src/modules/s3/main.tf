resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  bucket = each.key

  tags = {
    Name = each.key
  }
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = var.buckets
  bucket   = aws_s3_bucket.this[each.key].id

  versioning_configuration {
    status = each.value.versioning_enabled ? "Enabled" : "Suspended"
  }
}
