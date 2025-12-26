output "public_ip" {
  description = "ec2 public ip"
  value       = aws_instance.nginx_log_1224.public_ip
}

output "ssh_command" {
  description = "ssh ec2"
  value       = "ssh -i ~/.ssh/nginx_log_1224 ec2-user@${aws_instance.nginx_log_1224.public_ip}"
}
