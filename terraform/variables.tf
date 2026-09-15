variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, used for tagging and resource naming."
  type        = string
  default     = "ghost-production-aws"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the Ghost VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "Two public subnet CIDRs used by the public ALB and NAT gateway."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]

  validation {
    condition = (
      length(var.public_subnet_cidrs) == 2 &&
      alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "public_subnet_cidrs must contain exactly two valid IPv4 CIDR blocks."
  }
}

variable "application_subnet_cidrs" {
  description = "Two private subnet CIDRs used by ECS Fargate tasks."
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]

  validation {
    condition = (
      length(var.application_subnet_cidrs) == 2 &&
      alltrue([for cidr in var.application_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "application_subnet_cidrs must contain exactly two valid IPv4 CIDR blocks."
  }
}

variable "database_subnet_cidrs" {
  description = "Two isolated subnet CIDRs used by RDS."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]

  validation {
    condition = (
      length(var.database_subnet_cidrs) == 2 &&
      alltrue([for cidr in var.database_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "database_subnet_cidrs must contain exactly two valid IPv4 CIDR blocks."
  }
}

variable "domain_name" {
  description = "Fully qualified Ghost hostname managed manually in Cloudflare, for example ghost.example.com."
  type        = string

  validation {
    condition     = can(regex("^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\\.)+[A-Za-z]{2,63}$", var.domain_name))
    error_message = "domain_name must be a fully qualified hostname without a scheme or path."
  }
}

variable "acm_certificate_arn" {
  description = "ARN of an issued ACM certificate matching domain_name for ALB viewer TLS in the configured deployment partition and Region."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:acm:[^:]+:[0-9]{12}:certificate/.+$", var.acm_certificate_arn))
    error_message = "acm_certificate_arn must be an ACM certificate ARN for the configured deployment partition and Region."
  }
}

variable "ghost_image" {
  description = "Official Ghost 6.59.0 Alpine image pinned by immutable Docker manifest digest."
  type        = string

  validation {
    condition     = can(regex("^(docker\\.io/library/)?ghost@sha256:[0-9a-f]{64}$", var.ghost_image))
    error_message = "ghost_image must be the official Ghost image pinned as ghost@sha256:<64 lowercase hexadecimal characters>."
  }
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID containing the externally managed Ghost R2 bucket."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.cloudflare_account_id))
    error_message = "cloudflare_account_id must be a 32-character lowercase hexadecimal identifier."
  }
}

variable "r2_bucket_name" {
  description = "Name of the externally managed Cloudflare R2 bucket used by Ghost."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.r2_bucket_name))
    error_message = "r2_bucket_name must be 3-63 lowercase letters, digits, or hyphens and start/end with a letter or digit."
  }
}

variable "r2_media_hostname" {
  description = "Cloudflare R2 custom hostname serving Ghost media without a scheme or path."
  type        = string

  validation {
    condition     = can(regex("^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\\.)+[A-Za-z]{2,63}$", var.r2_media_hostname))
    error_message = "r2_media_hostname must be a fully qualified hostname without a scheme or path."
  }
}

variable "r2_credentials_secret_arn" {
  description = "ARN of the externally managed Secrets Manager secret containing R2 accessKeyId and secretAccessKey fields."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:secretsmanager:[^:]+:[0-9]{12}:secret:.+$", var.r2_credentials_secret_arn))
    error_message = "r2_credentials_secret_arn must be a Secrets Manager secret ARN."
  }
}

variable "allow_data_destruction" {
  description = "Emergency teardown switch. Keep false normally; true disables RDS deletion protection for an intentional destroy."
  type        = bool
  default     = false
}
