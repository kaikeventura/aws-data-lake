resource "aws_s3_bucket" "gold" {
  bucket = "show-tickets-lake-gold-${var.bucket_suffix}"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "gold" {
  bucket = aws_s3_bucket.gold.id
  versioning_configuration {
    status = "Enabled"
  }
}
