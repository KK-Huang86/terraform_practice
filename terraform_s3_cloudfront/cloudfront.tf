# 建立 CloudFront Distribution 和 OAC

# 1. 建立 Origin Access Control (OAC) -> 作為身分認證，得以通過 s3 bucket policy
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 2. 建立 CloudFront Distribution
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} CDN"
  default_root_object = "index.html"

  # 價格等級：使用北美、歐洲、亞洲的邊緣節點
  price_class = "PriceClass_200"

  # === 設定 Origin (來源) ===
  origin {
    # S3 的區域性網域名稱
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name

    # Origin ID（自訂的識別名稱）
    origin_id = "S3-${var.bucket_name}"

    # 連接 OAC（CloudFront 用這個身份訪問 S3）
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  # === 預設快取行為 ===
  default_cache_behavior {
    # 允許的 HTTP 方法
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # 強制使用 HTTPS
    viewer_protocol_policy = "redirect-to-https"

    # 快取時間設定
    min_ttl     = 0
    default_ttl = 3600  # 1 小時
    max_ttl     = 86400 # 24 小時

    # 啟用 Gzip 壓縮
    compress = true
  }

  # === 支援 Vue Router 的 SPA 路由 ===
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  # === 地理限制（這裡不限制） ===
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # === SSL/TLS 憑證設定 ===
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.project_name}-cdn"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
