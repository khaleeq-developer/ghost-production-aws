# GitHub Actions

Automated delivery is intentionally deferred until Stage 3. This directory is
kept as the future home of narrowly scoped workflows for:

- Terraform formatting and validation on pull requests
- Static analysis and security checks
- Reviewed Terraform plans
- Protected applies using GitHub OIDC to assume an AWS role

No workflow is currently active. The eventual implementation will not store
long-lived AWS access keys in GitHub.
