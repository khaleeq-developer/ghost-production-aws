output "state_bucket" {
  description = "Name of the S3 bucket holding Terraform remote state. Wire this into the root backend.tf."
  value       = aws_s3_bucket.state.id
}
