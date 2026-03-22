variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name (must be globally unique, no underscores)"
  type        = string
  default     = "my-static-portfolio-site"
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
  default     = "dev"
}
