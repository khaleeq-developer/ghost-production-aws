terraform {
  required_version = ">= 1.15.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.62"
    }
  }

  # Bootstrap intentionally uses LOCAL state: it creates the very S3 bucket that
  # the main config uses for remote state. The local *.tfstate is git-ignored.
}
