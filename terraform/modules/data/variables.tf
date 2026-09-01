variable "name_prefix" {
  description = "Prefix used for resource names and tags."
  type        = string
}

variable "database_subnet_ids" {
  description = "Isolated subnet IDs for the RDS subnet group."
  type        = list(string)

  validation {
    condition     = length(var.database_subnet_ids) >= 2
    error_message = "database_subnet_ids must contain at least two subnets."
  }
}

variable "rds_security_group_id" {
  description = "Security group ID that permits MySQL only from Ghost tasks."
  type        = string
}

variable "database_name" {
  description = "Name of the MySQL database used by Ghost."
  type        = string
  default     = "ghost"
}

variable "database_username" {
  description = "Master username used by Ghost. The password is generated."
  type        = string
  default     = "ghostadmin"
}

variable "instance_class" {
  description = "RDS instance class for the Stage 1 lab."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial RDS storage allocation in GiB."
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  description = "Number of days RDS automated backups are retained."
  type        = number
  default     = 7
}
