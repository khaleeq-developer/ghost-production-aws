data "aws_iam_policy_document" "media" {
  statement {
    sid    = "ManageGhostMediaObjects"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${var.media_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "media" {
  name_prefix = "ghost-media-"
  role        = aws_iam_role.task.id
  policy      = data.aws_iam_policy_document.media.json
}
