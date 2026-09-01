variable "aws_region" {
  description = "AWS region for the remote-state backend resources."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, used to prefix backend resource names."
  type        = string
  default     = "ghost-aws"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform remote state. Must be set (S3 names are global)."
  type        = string
}
