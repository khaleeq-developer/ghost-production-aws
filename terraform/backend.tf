terraform {
  # Remote state in S3 with native lockfile locking. The bucket is created once
  # by terraform/bootstrap. Fill in the bucket name from that config's output.
  #
  # NOTE: backend blocks cannot use variables. Either hardcode the values below,
  # or leave them partial and pass via `terraform init -backend-config=...`.
  backend "s3" {
    bucket       = "ghost-aws-tfstate-1a2b3c4d" # <- from bootstrap output
    key          = "ghost-production-aws/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # S3-native state locking (Terraform >= 1.11); replaces DynamoDB
  }
}
