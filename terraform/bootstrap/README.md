# Terraform backend bootstrap

This configuration creates the S3 bucket used by the main Terraform root for
remote state. It belongs in the repository: a new operator should be able to
reproduce the backend instead of relying on an undocumented, manually created
bucket.

The bootstrap root deliberately keeps its own state locally because it cannot
store state in a bucket that does not exist yet. Its real `terraform.tfvars`,
`.terraform/` directory and state files are ignored by Git.

## What it creates

- An encrypted, versioned S3 bucket
- Native S3 lockfile support for the main Terraform root
- A bucket policy denying insecure transport
- Retention of the five newest noncurrent state versions
- Expiration of older noncurrent versions after 90 days
- Protection against accidental Terraform destruction

No DynamoDB lock table is required. The main backend uses
`use_lockfile = true`, available in Terraform 1.11 and later.

## Usage

Run from the repository root:

```bash
cp terraform/bootstrap/terraform.tfvars.example terraform/bootstrap/terraform.tfvars
# Set a globally unique state_bucket_name in the copied file.

terraform -chdir=terraform/bootstrap init
terraform -chdir=terraform/bootstrap plan
terraform -chdir=terraform/bootstrap apply
terraform -chdir=terraform/bootstrap output -raw state_bucket
```

Copy the output into the `bucket` field in `terraform/backend.tf`, then
initialize the main Terraform root.

If the bucket already exists, retain the original bootstrap variable file and
local bootstrap state. Do not choose a new name or create a second backend.

## Destruction warning

Do not destroy this configuration while the main stack still uses the bucket.
Doing so would orphan its remote state. The bucket has Terraform lifecycle
protection, so removing it requires a deliberate code change after the main
stack has been destroyed or its state has been migrated.
