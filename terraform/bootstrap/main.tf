provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Component = "tf-backend-bootstrap"
    }
  }
}

# ─────────────────────────────────────────────────────────────
# S3 bucket that stores Terraform remote state for the project.
# Versioned + encrypted + fully private. State files hold secrets in
# plaintext, so this bucket must never be public.
# ─────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  # Guardrail: refuse to accidentally destroy the state bucket.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Keep a small recovery history while preventing old state versions from
# accumulating forever. S3 removes a noncurrent version only when it is both
# older than 90 days and outside the five most recent noncurrent versions.
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  depends_on = [aws_s3_bucket_versioning.state]

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      newer_noncurrent_versions = 5
      noncurrent_days           = 90
    }
  }

  # Saved plans can contain sensitive values. Keep them private in this bucket
  # and expire both current and versioned copies after the manual-apply window.
  rule {
    id     = "expire-ci-plans"
    status = "Enabled"

    filter {
      prefix = "github-plans/"
    }

    expiration {
      days = 2
    }

    noncurrent_version_expiration {
      noncurrent_days = 2
    }
  }
}

# Reject every S3 API request that is not transported over TLS. This is a deny
# policy only; it does not grant public or cross-account access to the bucket.
data "aws_iam_policy_document" "state_tls_only" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state_tls_only" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_tls_only.json
}

# Persistent GitHub identity belongs beside the state backend. Destroying the
# application root must not remove the roles needed to provision it again.
module "cicd" {
  source = "../modules/cicd"

  project                    = var.project
  github_repository          = var.github_repository
  github_repository_owner_id = var.github_repository_owner_id
  github_repository_id       = var.github_repository_id
  terraform_state_bucket     = aws_s3_bucket.state.id
  terraform_state_key        = var.terraform_state_key
  terraform_state_region     = var.aws_region
}
