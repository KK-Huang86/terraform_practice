variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "testdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "MyPassword123!"
}

variable "key_pair_name" {
  description = "EC2 Key Pair 名稱"
  type        = string
  default     = "1226_rds"
}

variable "ssh_public_key_path" {
  description = "SSH 公鑰路徑"
  type        = string
              # 可在 terraform.tfvars 進行設定（假設換電腦）
  default     = "~/.ssh/1226_rds.pub"
}
