variable "project" {
  description = "Project prefix used for CI/CD IAM resource names."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository authorized to use the roles, in exact owner/repository form."
  type        = string

  validation {
    condition     = can(regex("^[^/[:space:]]+/[^/[:space:]]+$", var.github_repository))
    error_message = "github_repository must be in exact owner/repository form."
  }
}

variable "terraform_state_bucket" {
  description = "Existing S3 backend bucket name."
  type        = string

  validation {
    condition     = length(trimspace(var.terraform_state_bucket)) > 0
    error_message = "terraform_state_bucket must not be empty."
  }
}

variable "terraform_state_key" {
  description = "Existing S3 backend state object key; the native lockfile uses this key plus .tflock."
  type        = string

  validation {
    condition     = length(trimspace(var.terraform_state_key)) > 0 && !startswith(var.terraform_state_key, "/")
    error_message = "terraform_state_key must be a non-empty relative S3 object key."
  }
}

variable "terraform_state_region" {
  description = "AWS Region containing the existing S3 backend bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$", var.terraform_state_region))
    error_message = "terraform_state_region must be a valid AWS Region identifier."
  }
}
