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
  description = "Two public subnet CIDRs used by the ALB and NAT gateway."
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
  description = "ARN of an issued ACM certificate matching domain_name in the same region as the ALB."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:acm:[^:]+:[0-9]{12}:certificate/.+$", var.acm_certificate_arn))
    error_message = "acm_certificate_arn must be a valid ACM certificate ARN."
  }
}
