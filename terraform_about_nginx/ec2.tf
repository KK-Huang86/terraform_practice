#設定 ec2
resource "aws_instance" "nginx_log_1224" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.ec2.key_name
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  
  # 👇 新增這些
  subnet_id                   = module.vpc.public_subnets[0]  # 放在 public subnet
  associate_public_ip_address = true                          # 分配公開 IP
  iam_instance_profile        = aws_iam_instance_profile.nginx.name  # 附加 IAM Role

    user_data = templatefile("${path.module}/script.sh", {
    s3_bucket_name = aws_s3_bucket.nginx-logs.bucket
    aws_region     = var.aws_region  
  })

  tags = {
    Name = "nginx-log-server"
  }
}


#設定公鑰
resource "aws_key_pair" "ec2" {
  key_name   = "nginx_log_1224"
  public_key = file("~/.ssh/nginx_log_1224.pub")
}

#aws_security_group設定

resource "aws_security_group" "ssh" {
  name        = "terraform-nginx-sg"
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