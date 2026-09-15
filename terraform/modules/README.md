# Terraform modules

| Module | Responsibility | Owner root |
| --- | --- | --- |
| `network` | VPC, subnets, routing, NAT, ALB, and security groups | `terraform` |
| `data` | RDS MySQL, database secret, backups, and deletion guards | `terraform` |
| `compute` | ECS Fargate, runtime IAM, logs, and Ghost/R2 configuration | `terraform` |
| `cicd` | GitHub OIDC provider and plan/apply roles | `terraform/bootstrap` |

The main root is disposable. Bootstrap is persistent so destroying the Ghost
stack does not remove the remote-state bucket or the identity CI needs to
recreate it.

Cloudflare R2, its custom hostname, and its API token are external resources.
The compute module receives their identifiers and the ARN of the AWS secret
containing the R2 credentials.
