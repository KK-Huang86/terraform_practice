output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.app.public_ip
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "RDS address (without port)"
  value       = aws_db_instance.postgres.address
}

output "connection_command" {
  description = "SSH 連線指令"
  value       = "ssh -i ${aws_key_pair.ec2.key_name}.pem ec2-user@${aws_instance.app.public_ip}"
}