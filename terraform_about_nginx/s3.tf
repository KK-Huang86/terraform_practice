resource "aws_s3_bucket" "nginx-logs" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = var.project_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# 封鎖所有公開訪問（private）
resource "aws_s3_bucket_public_access_block" "nginx-logs" {
  bucket = aws_s3_bucket.nginx-logs.id

  block_public_acls       = true # 封鎖公開的 ACL
  block_public_policy     = true # 封鎖公開的 Bucket Policy
  ignore_public_acls      = true # 忽略所有公開的 ACL
  restrict_public_buckets = true # 限制公開的 bucket
}