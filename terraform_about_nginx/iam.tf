# IAM Role - EC2 可以 assume
resource "aws_iam_role" "nginx" {
  name = "nginx-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# IAM Policy - 允許寫 S3
resource "aws_iam_policy" "s3_upload" {
  name = "nginx-s3-upload"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "${aws_s3_bucket.nginx-logs.arn}",
        "${aws_s3_bucket.nginx-logs.arn}/*"
      ]
    }]
  })
}

# 綁定 Policy 到 Role
resource "aws_iam_role_policy_attachment" "nginx_s3" {
  role       = aws_iam_role.nginx.name
  policy_arn = aws_iam_policy.s3_upload.arn
}

# Instance Profile（EC2 用這個附加 Role）
resource "aws_iam_instance_profile" "nginx" {
  name = "nginx-profile"
  role = aws_iam_role.nginx.name
}