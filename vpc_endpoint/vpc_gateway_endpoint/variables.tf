variable "aws_region"{
  description = "AWS 區域"
  type = string
  default = "ap-northeast-1"
}

variable "project_name" {
  description = "專案名稱"
  type        = string
  default     = "vpc_gateway_endpoint"
}

variable "s3_bucket_name" {
  description = "S3 bucket 名稱"
  type        = string
  # 實際值在 terraform.tfvars
}