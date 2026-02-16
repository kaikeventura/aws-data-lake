resource "aws_s3_bucket" "silver" {
  bucket = "show-tickets-lake-silver-${var.bucket_suffix}"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "silver" {
  bucket = aws_s3_bucket.silver.id
  versioning_configuration {
    status = "Enabled"
  }
}
