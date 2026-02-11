resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = {
    Name        = var.project_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# 封鎖所有公開訪問（讓 S3 變成 private）
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true # 封鎖公開的 ACL
  block_public_policy     = true # 封鎖公開的 Bucket Policy
  ignore_public_acls      = true # 忽略所有公開的 ACL
  restrict_public_buckets = true # 限制公開的 bucket
}


# 不公開 Bucket Policy，允許 Cloudfront 的私人連線

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  # 這個 policy 必須等 CloudFront 建立後才能套用
  depends_on = [
    aws_cloudfront_distribution.website
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"

        # 只允許 CloudFront 服務
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }

        # 只允許讀取
        Action = "s3:GetObject"

        # 套用到這個 bucket 的所有檔案
        Resource = "${aws_s3_bucket.website.arn}/*"

        # 認可的 CloudFront distribution
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      }
    ]
  })
}
