resource "aws_instance" "cloudwatch" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnets[0]

  vpc_security_group_ids = [aws_security_group.cloudwatch-sg.id]
  key_name               = aws_key_pair.ec2.key_name
  iam_instance_profile   = aws_iam_instance_profile.cloudwatch_agent.name
  # 啟用詳細監控 (相隔1分鐘)
  monitoring = true

  tags = {
    Name = "cloudwatch"
  }
}

resource "aws_key_pair" "ec2" {
  key_name   = "cloudwatch-key"
  public_key = file("~/.ssh/1226_rds.pub")   # 共用公鑰
}


resource "aws_security_group" "cloudwatch-sg" {
  name        = "cloudwatch-sg"
  description = "Allow SSH, HTTP, HTTPS"
  vpc_id = module.vpc.vpc_id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}