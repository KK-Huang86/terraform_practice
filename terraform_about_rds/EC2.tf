

# EC2 Instance
resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = aws_key_pair.ec2.key_name

  # User data - 安裝必要套件
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y postgresql15 python3 python3-pip git
              pip3 install psycopg2-binary
              EOF

  tags = {
    Name = "rds-test-ec2"
  }
}


# EC2 Security Group
resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 允許所有 outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow PostgreSQL from EC2"
  vpc_id      = aws_vpc.main.id

  # 允許來自 EC2 的 PostgreSQL 連線
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
    description     = "PostgreSQL from EC2"
  }

  tags = {
    Name = "rds-sg"
  }
}


# 公鑰 key pair
resource "aws_key_pair" "ec2" {
  key_name   = var.key_pair_name
  public_key = file(var.ssh_public_key_path)
}