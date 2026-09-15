# Terraform bootstrap

This local-state root creates resources that must survive application teardown:

- encrypted and versioned S3 remote-state bucket
- native S3 lockfile access
- GitHub Actions OIDC provider
- separate pull-request plan and production apply roles

## One-time setup

Copy `terraform.tfvars.example` to the ignored `terraform.tfvars`, then set the
globally unique bucket name and GitHub repository in `owner/repository` form.

From the repository root:

```bash
terraform -chdir=terraform/bootstrap init
terraform -chdir=terraform/bootstrap plan
terraform -chdir=terraform/bootstrap apply
terraform -chdir=terraform/bootstrap output
```

The main root's `backend.tf` must identify the same bucket, Region, and state
key. Add the three relevant outputs to GitHub as:

- `state_bucket` → `TERRAFORM_STATE_BUCKET`
- `github_actions_plan_role_arn` → `TERRAFORM_PLAN_ROLE_ARN`
- `github_actions_apply_role_arn` → `TERRAFORM_APPLY_ROLE_ARN`

The bootstrap state remains local because this root creates its own backend.
Preserve its ignored tfvars and state files securely.

## Lifecycle

Do not destroy bootstrap while the main stack uses its state or CI roles. The
bucket has `prevent_destroy`; deliberate removal requires changing that guard
only after the application state has been destroyed or migrated.
