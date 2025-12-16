# 主要資源定義

# Security Group 允許 SSH 連線
resource "aws_security_group" "ssh" {
  name        = "terraform-1215-ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-1215-ssh"
  }
}

resource "aws_instance" "test1215" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ec2.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "1215test_for_terraform"
  }
}

resource "aws_key_pair" "ec2" {
  key_name   = "terraform-1215-ec2"
  public_key = file("~/.ssh/terraform_1215_ec2.pub")
}
