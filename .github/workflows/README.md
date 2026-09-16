# Terraform workflows

`terraform-pr.yml` runs formatting, validation, and TFLint checks. For a
same-repository pull request, it also assumes the bootstrap plan role and runs
a speculative plan. Forked pull requests never receive AWS credentials.

`terraform-apply.yml` plans every push to `main` with the plan role and stores
the binary plan briefly in the private state bucket. A manual run on the same
commit, confirmed with `APPLY`, downloads, verifies, and applies that exact
plan with the production role.

`terraform-destroy.yml` is manual-only. Running it on `main` with `DESTROY`
creates, displays, and applies an exact destroy plan for the application stack.

Before AWS-backed jobs can run:

- apply `terraform/bootstrap` once
- configure the `plan` and `production` environment variables in the root README
- leave `plan` unrestricted and restrict `production` to `main`

After changes to the CI roles or plan-storage policy, apply the bootstrap root
again before relying on the production workflows.

Bootstrap is intentionally outside these workflows. This prevents application
teardown from removing or rewriting its own CI identity.
