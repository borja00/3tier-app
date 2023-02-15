data "aws_iam_policy_document" "push_s3" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:ListObjectsV2",
      "s3:CopyObject"
    ]

    resources = [
      "arn:aws:s3:::${var.aws_s3_cdn_content_bucket}*",
    ]
  }

}

resource "aws_iam_policy" "push_s3" {
  name        = "${var.env_long}-push-s3"
  description = "${var.env_long} AWS S3 access for CI/CD"
  path        = "/"
  policy      = data.aws_iam_policy_document.push_s3.json
}


resource "aws_iam_user_policy_attachment" "attach-s3-cdn-content-policy" {
  count      = 1
  user       = aws_iam_user.ecr-deploy.0.name
  policy_arn = aws_iam_policy.push_s3.arn
}
