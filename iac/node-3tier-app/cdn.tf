locals {
  s3_origin_id                   = "myS3Origin"
  default_cloudfront_origin_name = "content"
  default_s3_bucket_name         = var.aws_s3_cdn_content_bucket
  public_bucket_path             = "public/*"
}

resource "aws_s3_bucket" "default" {
  count  = 1
  bucket = local.default_s3_bucket_name
  acl    = "private"
  tags = {
    Name        = local.default_s3_bucket_name
    Environment = var.env_long
  }
}

resource "aws_cloudfront_origin_access_identity" "default" {
  count   = 1
  comment = "${var.env_long} Origin Access Identity"
}

data "aws_iam_policy_document" "s3_policy" {
  count = 1
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.default.0.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.default.0.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "default" {
  count  = 1
  bucket = aws_s3_bucket.default.0.id
  policy = data.aws_iam_policy_document.s3_policy.0.json
}

resource "aws_s3_bucket_public_access_block" "default" {
  count                   = 1
  bucket                  = aws_s3_bucket.default.0.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_cloudfront_distribution" "content" {
  count = 1

  origin {
    domain_name = aws_s3_bucket.default.0.bucket_regional_domain_name
    origin_id   = "${local.default_cloudfront_origin_name}-${local.s3_origin_id}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default.0.cloudfront_access_identity_path
    }
  }

  enabled         = true
  is_ipv6_enabled = false
  comment         = "${var.env_long} - CDN "

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${local.default_cloudfront_origin_name}-${local.s3_origin_id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = var.env_long
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

}

resource "aws_ssm_parameter" "cdn_domain" {
  count       = 1
  name        = "/${var.env_long}/cdn/domain"
  description = "${var.env_long} CDN domian"
  type        = "SecureString"
  value       = aws_cloudfront_distribution.content.0.domain_name
  tags        = local.tags
}
