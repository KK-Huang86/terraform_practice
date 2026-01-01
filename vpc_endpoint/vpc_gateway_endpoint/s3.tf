resource "aws_s3_bucket" "gateway_endpoint" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = var.project_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# 封鎖所有公開訪問（private）
resource "aws_s3_bucket_public_access_block" "gateway_endpoint" {
  bucket = aws_s3_bucket.gateway_endpoint.id

  block_public_acls       = true # 封鎖公開的 ACL
  block_public_policy     = true # 封鎖公開的 Bucket Policy
  ignore_public_acls      = true # 忽略所有公開的 ACL
  restrict_public_buckets = true # 限制公開的 bucket
}

# bucket policy

resource "aws_s3_bucket_policy" "private_only" {
  bucket = aws_s3_bucket.gateway_endpoint.id


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccessOnlyFromVPCE"
        Effect = "Allow"

        # 允許該 VPC的所有服務（？）
        Principal = "*"

        # 只允許讀取
        Action = "s3:GetObject"

        # 套用到這個 bucket 的所有檔案
        Resource = "${aws_s3_bucket.gateway_endpoint.arn}/*"

        # 認可的 CloudFront distribution
        Condition = {
          StringEquals = {
            "aws:sourceVpce" = aws_vpc_endpoint.s3_gateway.id
          }
        }
      }
    ]
  })
}