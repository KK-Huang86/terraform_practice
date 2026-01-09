resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true # VPC 內自動產生 DNS名稱 interface 需要，才知道要送哪
  enable_dns_support = true # VPC 內啟用 AWS DNS 服務（route53）

  tags = {
    Name = "interface_endpoint_vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false  # Private Subnet 不需要 Public IP

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_route_table" "subnet_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "subnet-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.subnet_rt.id
}


# -------- 以下為 Interface Endpoint  設定

# VPC Interface Endpoint for SQS
resource "aws_vpc_endpoint" "sqs" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type = "Interface"

  # 指定要在哪些 Private Subnets 建立 ENI
  subnet_ids = [
    aws_subnet.private.id,
  ]

  # 關聯安全群組
  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  # 啟用 Private DNS
  private_dns_enabled = true

  tags = {
    Name = "sqs-vpc-endpoint"
  }
}

# VPC Endpoint 的安全群組
resource "aws_security_group" "vpc_endpoint" {
  description = "Allow HTTPS traffic to VPC Endpoint"
  vpc_id           = aws_vpc.main.id

  # 允許來自 VPC 內部的 HTTPS 請求
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]  # 10.0.0.0/16
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-endpoint-sg"
  }
}


#-------- SQS Queue 設定

resource "aws_sqs_queue" "test_queue" {
  name = "interface-endpoint-test-queue"

  tags = {
    Name = "test-queue"
  }
}