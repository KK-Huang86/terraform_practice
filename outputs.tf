# 輸出定義
output "public_ip" {
  description = "ec2 public ip"
  value       = aws_instance.test1215.public_ip
}

output "ssh_command" {
  description = "ssh ec2"
  value       = "ssh -i ~/.ssh/terraform_1215_ec2 ec2-user@${aws_instance.test1215.public_ip}"
}
