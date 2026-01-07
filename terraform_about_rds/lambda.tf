# 透過 lambda 連接 rds

# 打包要讓lambda 執行的程式碼 
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}


# 設定  lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 基本執行權限（CloudWatch Logs）
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC 執行權限（Lambda 放進 VPC 需要）
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Secrets Manager 讀取權限
resource "aws_iam_policy" "lambda_secrets_policy" {
  name = "lambda-secrets-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "secretsmanager:GetSecretValue"
      Effect   = "Allow"
      Resource = aws_secretsmanager_secret.rds_credentials.arn
    }]
  })
}

# 賦予權限
resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
}

# Lambda Security Group

resource "aws_security_group" "lambda" {
  name        = "lambda-sg"
  description = "Security group for Lambda"
  vpc_id      = aws_vpc.main.id

  # 允許連到 VPC Endpoint (HTTPS) -> 為的是取得 secrets
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # 允許所有 outbound（連 RDS、Secrets Manager）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-sg"
  }
}

# 允許 Lambda 連到 RDS（加到 RDS Security Group）
resource "aws_security_group_rule" "lambda_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda.id
  security_group_id        = aws_security_group.rds.id
}

# Lambda Function
resource "aws_lambda_function" "my_function" {
  function_name    = "connect_rds"
  role             = aws_iam_role.lambda_role.arn
  handler          = "connect_rds.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30

  # 使用公開的 psycopg2 Layer（社群維護）
  layers = ["arn:aws:lambda:ap-northeast-1:770693421928:layer:Klayers-p312-psycopg2-binary:1"]

  # 將 Lambda 放進 VPC
  vpc_config {
    subnet_ids         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  # 環境變數（給 Python 程式碼用）
  environment {
    variables = {
      DB_HOST     = aws_db_instance.postgres.address
      DB_NAME     = var.db_name
      SECRET_NAME = aws_secretsmanager_secret.rds_credentials.name
    }
  }

  tags = {
    Name = "my-lambda"
  }
}

# Secrets Manager（安全存放 RDS 密碼）


resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "rds-credentials"
}

resource "aws_secretsmanager_secret_version" "rds_credentials_version" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_username # 存放 db username 
    password = var.db_password # 以及 db password
  })
}


# VPC Endpoint for Secrets Manager
# Lambda 在 VPC 內需要這個才能連到 Secrets Manager

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  security_group_ids  = [aws_security_group.lambda.id]
  private_dns_enabled = true

  tags = {
    Name = "secretsmanager-endpoint"
  }
}