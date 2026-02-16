resource "aws_s3_bucket" "bronze" {
  bucket = "show-tickets-lake-bronze-${var.bucket_suffix}"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "bronze" {
  bucket = aws_s3_bucket.bronze.id
  versioning_configuration {
    status = "Enabled"
  }
}
