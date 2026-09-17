# Terraform workflows

`terraform-pr.yml` runs formatting, validation, and TFLint checks, then
assumes the bootstrap plan role for a speculative plan. Both jobs are guarded
so that only pull requests opened from this repository run at all; a forked
pull request triggers nothing and can never receive AWS credentials.

`terraform-apply.yml` plans every push to `main` with the plan role and stores
the binary plan briefly in the private state bucket. A manual run with
`action=plan` regenerates the saved plan for the current `main` commit, which
is needed after state changes outside CI (the old plan is rejected as stale).
A manual run with `action=apply`, confirmed with `APPLY`, downloads, verifies,
and applies that exact plan with the production role and prints the stack
outputs in the run summary. A manual run with `action=output` prints those
outputs at any time using only the read-only plan role.

`terraform-destroy.yml` is manual-only. Running it on `main` with `DESTROY`
creates, displays, and applies an exact destroy plan for the application stack.

Before AWS-backed jobs can run:

- apply `terraform/bootstrap` once
- create the `plan` and `production` GitHub environments with the variables
  below; leave `plan` unrestricted and restrict `production` to `main`

| Variable | Environment | Source |
| --- | --- | --- |
| `AWS_REGION` | both | deployment Region, for example `us-east-1` |
| `PROJECT` | both | project name used for resource naming; must match the bootstrap root's `project` |
| `TERRAFORM_STATE_BUCKET` | both | bootstrap output `state_bucket` |
| `DOMAIN_NAME` | both | Ghost site hostname |
| `ACM_CERTIFICATE_ARN` | both | issued certificate for `DOMAIN_NAME` |
| `GHOST_IMAGE` | both | `ghost@sha256:<digest>` |
| `CLOUDFLARE_ACCOUNT_ID` | both | Cloudflare account containing the R2 bucket |
| `R2_BUCKET_NAME` | both | R2 bucket for Ghost uploads |
| `R2_MEDIA_HOSTNAME` | both | R2 custom domain serving media |
| `R2_CREDENTIALS_SECRET_ARN` | both | Secrets Manager secret holding the R2 token |
| `TERRAFORM_PLAN_ROLE_ARN` | `plan` only | bootstrap output `github_actions_plan_role_arn` |
| `TERRAFORM_APPLY_ROLE_ARN` | `production` only | bootstrap output `github_actions_apply_role_arn` |

After changes to the CI roles or plan-storage policy, apply the bootstrap root
again before relying on the production workflows.

Bootstrap is intentionally outside these workflows. This prevents application
teardown from removing or rewriting its own CI identity.
