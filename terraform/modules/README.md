# Terraform modules

The root configuration in `terraform/` composes four focused modules for one
environment.

| Module | Responsibility |
| --- | --- |
| `network` | VPC, six subnets, routing, NAT Gateway, ALB, listeners, target group and security groups |
| `data` | RDS MySQL, generated credentials, Secrets Manager, backups and deletion safeguards |
| `media` | Private encrypted/versioned S3 storage and CloudFront delivery with OAC |
| `compute` | IAM roles, CloudWatch logs, ECS, and Ghost's built-in S3Storage configuration |

Module boundaries follow the request path:

```text
network outputs ──► data ──► compute
                         ▲
media outputs ───────────┘
```

The network module supplies private subnets and security-group boundaries. The
data module supplies the database secret. The media module supplies the bucket
and CDN boundary. The compute module consumes those outputs to run Ghost without
a public IP or long-lived AWS credentials.

Application-wide edge protection and observability are not currently
implemented.
