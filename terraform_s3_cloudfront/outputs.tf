output "s3_bucket_name" {
  description = "S3 bucket 名稱"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID（用來清除快取）"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "CloudFront 網域名稱"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "website_url" {
  description = "網站網址"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}
