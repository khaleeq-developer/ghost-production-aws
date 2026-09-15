terraform {
  # Remote state in S3 with native lockfile locking. The bucket is intentionally
  # omitted so every operator supplies their bootstrap output and AWS Region
  # through `terraform init -backend-config=...` instead of committing
  # account-specific backend values.
  backend "s3" {
    bucket       = "ghost-aws-tfstate-1a2b3c4d"
    key          = "ghost-production-aws/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # S3-native state locking (Terraform >= 1.11); replaces DynamoDB
  }
}
