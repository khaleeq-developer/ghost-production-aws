# Terraform workflows

`terraform-pr.yml` runs formatting, validation, TFLint, and Trivy checks. For a
same-repository pull request, it also assumes the bootstrap plan role and runs
a speculative plan. Forked pull requests never receive AWS credentials.

`terraform-apply.yml` runs after relevant changes reach `main`, or by manual
dispatch. It enters the protected `production` environment, assumes the apply
role, displays a saved plan, and applies that exact plan.

Before AWS-backed jobs can run:

- apply `terraform/bootstrap` once
- configure the repository variables listed in the root README
- create the `production` GitHub environment and restrict it to `main`

Bootstrap is intentionally outside these workflows. This prevents application
teardown from removing or rewriting its own CI identity.
