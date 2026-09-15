variable "aws_region" {
  description = "AWS region for the remote-state backend resources."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, used to prefix backend resource names."
  type        = string
  default     = "ghost-production-aws"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform remote state. Must be set (S3 names are global)."
  type        = string
}

variable "terraform_state_key" {
  description = "S3 object key used by the main Terraform root."
  type        = string
  default     = "ghost-production-aws/terraform.tfstate"

  validation {
    condition     = length(trimspace(var.terraform_state_key)) > 0 && !startswith(var.terraform_state_key, "/")
    error_message = "terraform_state_key must be a non-empty relative S3 object key."
  }
}

variable "github_repository" {
  description = "GitHub repository authorized to use the CI roles, in owner/repository form."
  type        = string

  validation {
    condition     = can(regex("^[^/[:space:]]+/[^/[:space:]]+$", var.github_repository))
    error_message = "github_repository must be in exact owner/repository form."
  }
}

variable "github_repository_owner_id" {
  description = "Immutable numeric GitHub account ID of the repository owner."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_owner_id))
    error_message = "github_repository_owner_id must contain only digits."
  }
}

variable "github_repository_id" {
  description = "Immutable numeric GitHub repository ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_id))
    error_message = "github_repository_id must contain only digits."
  }
}
