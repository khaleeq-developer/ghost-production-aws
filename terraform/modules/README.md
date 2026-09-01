# Terraform modules

The root configuration in `terraform/` composes three focused modules for one
environment.

| Module | Status | Responsibility |
| --- | --- | --- |
| `network` | Stage 1 implemented | VPC, six subnets, routing, NAT Gateway, ALB, listeners, target group and security groups |
| `data` | Stage 1 implemented | RDS MySQL, generated credentials and Secrets Manager; S3 media is planned for Stage 2 |
| `compute` | Stage 1 implemented | IAM roles, CloudWatch log group, ECS cluster, task definition and one-task Fargate service |

Module boundaries follow the request path:

```text
network outputs ──► data
       │              │
       └──────────────┴──► compute
```

The network module supplies private subnets and security-group boundaries. The
data module supplies the database secret. The compute module consumes those
outputs to run Ghost without a public IP.

Later-stage edge, delivery and observability resources will be added only when
their stage is implemented; this README does not describe unimplemented modules
as if they already exist.
