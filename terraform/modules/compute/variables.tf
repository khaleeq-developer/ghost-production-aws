variable "name_prefix" {
  description = "Prefix used for resource names and tags."
  type        = string
}

variable "aws_region" {
  description = "AWS region used by the CloudWatch Logs driver."
  type        = string
}

variable "application_subnet_ids" {
  description = "Private application subnet IDs for Fargate tasks."
  type        = list(string)

  validation {
    condition     = length(var.application_subnet_ids) >= 2
    error_message = "application_subnet_ids must contain at least two subnets."
  }
}

variable "ecs_security_group_id" {
  description = "Security group ID for Ghost tasks."
  type        = string
}

variable "target_group_arn" {
  description = "ALB target-group ARN used by the ECS service."
  type        = string
}

variable "ghost_url" {
  description = "Canonical HTTPS URL used by Ghost."
  type        = string
}

variable "database_secret_arn" {
  description = "Secrets Manager ARN containing the Ghost database connection fields."
  type        = string
}

variable "ghost_image" {
  description = "Official Ghost container image pinned by immutable manifest digest."
  type        = string

  validation {
    condition     = can(regex("^(docker\\.io/library/)?ghost@sha256:[0-9a-f]{64}$", var.ghost_image))
    error_message = "ghost_image must use the official Ghost repository and a sha256 digest."
  }
}

variable "media_bucket_name" {
  description = "Name of the externally managed Cloudflare R2 bucket used by Ghost's built-in S3Storage adapter."
  type        = string
}

variable "media_endpoint" {
  description = "Cloudflare R2 S3-compatible HTTPS endpoint used by Ghost."
  type        = string

  validation {
    condition     = can(regex("^https://[0-9a-f]{32}\\.r2\\.cloudflarestorage\\.com$", var.media_endpoint))
    error_message = "media_endpoint must be a Cloudflare account-level R2 HTTPS endpoint."
  }
}

variable "media_credentials_secret_arn" {
  description = "Secrets Manager ARN containing R2 accessKeyId and secretAccessKey fields."
  type        = string
}

variable "media_url" {
  description = "Cloudflare R2 custom-domain HTTPS origin returned by Ghost for uploaded media."
  type        = string

  validation {
    condition     = can(regex("^https://[^/]+$", var.media_url))
    error_message = "media_url must be an HTTPS origin without a trailing slash or path."
  }
}

variable "ghost_port" {
  description = "Port exposed by the Ghost container."
  type        = number
  default     = 2368
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 1024
}
