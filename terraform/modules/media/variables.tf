variable "name_prefix" {
  description = "Prefix used for media resource names and tags."
  type        = string
}

variable "force_destroy" {
  description = "Allow Terraform to delete all versioned media objects when destroying the bucket. Keep false during normal operation."
  type        = bool
  default     = false
}

