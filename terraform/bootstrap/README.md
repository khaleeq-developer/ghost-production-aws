# Bootstrap root — persistent state and CI identity

Everything the application stack depends on but must never be able to
destroy lives here, applied once from an operator's machine with local state:

| Resource | Why it is persistent |
| --- | --- |
| **S3 state bucket** — versioned, AES-256 encrypted, public access blocked, TLS-only bucket policy | Holds the application root's remote state and native `.tflock` lockfile |
| **Saved-plan prefix** `github-plans/` with a 2-day expiry | CI stores the binary plan for a `main` commit here until a human applies it |
| **GitHub OIDC provider** | Lets GitHub Actions exchange its job token for AWS credentials — no access keys |
| **`…-github-terraform-plan` role** | Read-only: state, describe calls, plan upload. Trust is limited to the `plan` environment |
| **`…-github-terraform-apply` role** | Scoped write access to exactly the resource families the application root manages. Trust is limited to the `production` environment |

Both roles' trust policies match `repo:<owner>@<owner-id>/<repo>@<repo-id>`,
GitHub's immutable-ID subject format, so a renamed, transferred, or forked
repository cannot assume them. The role policies live in
[`../modules/cicd`](../modules/cicd/main.tf) and enumerate every allowed
action rather than using wildcards.

## One-time setup

1. Copy `terraform.tfvars.example` to `terraform.tfvars` (git-ignored) and set:
   - `state_bucket_name` — globally unique
   - `github_repository` — `owner/repository`
   - `github_repository_owner_id` and `github_repository_id` — numeric IDs from
     `gh api users/<owner> --jq .id` and `gh api repos/<owner>/<repo> --jq .id`
2. Apply with an administrative AWS identity, from the repository root:

   ```bash
   terraform -chdir=terraform/bootstrap init
   terraform -chdir=terraform/bootstrap plan
   terraform -chdir=terraform/bootstrap apply
   terraform -chdir=terraform/bootstrap output
   ```

3. Copy the outputs into the GitHub environments:

   | Output | GitHub variable | Environment |
   | --- | --- | --- |
   | `state_bucket` | `TERRAFORM_STATE_BUCKET` | `plan` and `production` |
   | `github_actions_plan_role_arn` | `TERRAFORM_PLAN_ROLE_ARN` | `plan` only |
   | `github_actions_apply_role_arn` | `TERRAFORM_APPLY_ROLE_ARN` | `production` only |

The workflows pass the bucket, key, and Region to `terraform init` with
`-backend-config`, so nothing account-specific needs to be committed.

## Keeping it in sync

The CI roles are the one part of the system CI cannot update itself. After
any change to `modules/cicd` — for example adding an IAM action that a new
resource needs — re-run `terraform apply` here before relying on the
workflows. A missing action surfaces in the workflow log as an
`AccessDenied` naming the exact action to add.

State for this root stays local by design (it creates its own backend). Keep
the ignored `terraform.tfstate` and `terraform.tfvars` somewhere safe.

## Lifecycle

- **Do not destroy** while the application stack exists or its state is in
  the bucket; the workflows would lose both their identity and their state.
- The bucket carries `prevent_destroy`. Deliberate teardown, after the
  application stack has been destroyed, means removing that guard first.
- Destroying bootstrap makes the workflows inert: with no roles to assume,
  nothing in this repository can touch AWS. That is the intended end state for
  the archived portfolio deployment.
