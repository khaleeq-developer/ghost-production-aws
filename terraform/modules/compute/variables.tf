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
  description = "Pinned official Ghost container image used in Stage 1."
  type        = string
  default     = "ghost:6.59.0-alpine"
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
