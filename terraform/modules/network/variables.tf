variable "name_prefix" {
  description = "Prefix used for resource names and Name tags."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "Two public subnet CIDRs, one for each availability zone."
  type        = list(string)

  validation {
    condition = (
      length(var.public_subnet_cidrs) == 2 &&
      alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "public_subnet_cidrs must contain exactly two valid IPv4 CIDR blocks."
  }
}

variable "application_subnet_cidrs" {
  description = "Two private application subnet CIDRs, one for each availability zone."
  type        = list(string)

  validation {
    condition = (
      length(var.application_subnet_cidrs) == 2 &&
      alltrue([for cidr in var.application_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "application_subnet_cidrs must contain exactly two valid IPv4 CIDR blocks."
  }
}

variable "database_subnet_cidrs" {
  description = "Two isolated database subnet CIDRs, one for each availability zone."
  type        = list(string)

  validation {
    condition = (
      length(var.database_subnet_cidrs) == 2 &&
      alltrue([for cidr in var.database_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "database_subnet_cidrs must contain exactly two valid IPv4 CIDR blocks."
  }
}

variable "ghost_port" {
  description = "Port exposed by the Ghost container."
  type        = number
  default     = 2368

  validation {
    condition     = var.ghost_port >= 1 && var.ghost_port <= 65535
    error_message = "ghost_port must be between 1 and 65535."
  }
}

variable "acm_certificate_arn" {
  description = "ARN of the issued ACM certificate used by the ALB HTTPS listener."
  type        = string
}
