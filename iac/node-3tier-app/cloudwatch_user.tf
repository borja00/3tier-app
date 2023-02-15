data "aws_iam_policy_document" "cloudwatch" {
  statement {
    sid = "AllowReadingMetricsFromCloudWatch"

    actions = [
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetInsightRuleReport"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "AllowReadingTagsInstancesRegionsFromEC2"

    actions = [
      "ec2:DescribeTags", "ec2:DescribeInstances", "ec2:DescribeRegions"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "AllowReadingResourcesForTags"

    actions = [
      "tag:GetResources"
    ]

    resources = [
      "*",
    ]
  }

}

resource "aws_iam_policy" "cloudwatch" {
  name   = "ecs-monitoring-cloudwatch"
  description = "Cloudwatch Monitoring access for grafana"
  path   = "/"
  policy = data.aws_iam_policy_document.cloudwatch.json
}

resource "aws_iam_user" "grafana-cloudwatch" {
  count         = 1
  name          = "${var.env_short}-grafana-cloudwatch-${var.shared_region}"
  force_destroy = true
}

resource "aws_iam_access_key" "grafana-cloudwatch" {
  count = 1
  user  = aws_iam_user.grafana-cloudwatch.0.name
}


resource "aws_iam_user_policy_attachment" "grafana-cloudwatch-policy-attachment" {
  policy_arn       = aws_iam_policy.cloudwatch.arn
  user = aws_iam_user.grafana-cloudwatch.0.name
}

resource "aws_ssm_parameter" "grafana_aws_access_key_id" {
  count = 1
  name        = "/${var.env_long}/grafana/aws/access_key_id"
  description = "${var.env_long} AWS Key id for grafana cloudwatch datasource"
  type        = "SecureString"
  value       = aws_iam_access_key.grafana-cloudwatch.0.id
  tags = local.tags
}

resource "aws_ssm_parameter" "grafana_aws_secret_access_key" {
  count = 1
  name        = "/${var.env_long}/grafana/aws/secret_access_key"
  description = "${var.env_long} AWS secret Key for grafana cloudwatch datasource"
  type        = "SecureString"
  value       = aws_iam_access_key.grafana-cloudwatch.0.secret
  tags = local.tags
}


resource "aws_ssm_parameter" "grafana_admin_password" {
  count = 1
  name        = "/${var.env_long}/grafana/admin_password"
  description = "${var.env_long} Grafana admin password"
  type        = "SecureString"
  value       = random_password.grafana_admin_password.result
  tags = local.tags
}

resource "random_password" "grafana_admin_password" {
  length  = 16
  special = false
  number  = true
}

