# Terraform workflows

`terraform-pr.yml` runs formatting, validation, and TFLint checks. For a
same-repository pull request, it also assumes the bootstrap plan role and runs
a speculative plan. Forked pull requests never receive AWS credentials.

`terraform-apply.yml` runs after relevant changes reach `main`, or by manual
dispatch. It enters the protected `production` environment, assumes the apply
role, displays a saved plan, and applies that exact plan.

Before AWS-backed jobs can run:

- apply `terraform/bootstrap` once
- configure the `plan` and `production` environment variables in the root README
- leave `plan` unrestricted and restrict `production` to `main`

Bootstrap is intentionally outside these workflows. This prevents application
teardown from removing or rewriting its own CI identity.
