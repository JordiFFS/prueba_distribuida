resource "aws_s3_bucket" "app_bucket" {
  bucket_prefix = "${var.app_name}-"

  tags = {
    Name = "${var.app_name}-bucket"
  }
}

resource "aws_s3_bucket_versioning" "app_bucket_versioning" {
  bucket = aws_s3_bucket.app_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket_encryption" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_bucket_pab" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "app_bucket_logging" {
  bucket = aws_s3_bucket.app_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "app-logs/"
}

resource "aws_s3_bucket" "log_bucket" {
  bucket_prefix = "${var.app_name}-logs-"

  tags = {
    Name = "${var.app_name}-log-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket_pab" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}