
variable "aws_region" {
  description = "AWS 區域"
  type        = string
  default     = "ap-northeast-1" # 東京
}

variable "bucket_name" {
  description = "S3 bucket 名稱"
  type        = string
}

variable "project_name" {
  description = "專案名稱"
  type        = string
  default     = "vue-website"
}
