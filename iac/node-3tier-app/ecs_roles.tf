resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.env_short}-ecsTaskRole-${var.shared_region}"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.env_short}-ecsTaskExecutionRole-${var.shared_region}"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

data "aws_iam_policy_document" "read_ssm" {
  statement {
    sid = "1"

    actions = [
      "ssm:GetParameters",
    ]

    resources = [
      "arn:aws:ssm:${var.shared_region}:${var.aws_account_id}:parameter/${var.env_long}*",
    ]
  }

}

resource "aws_iam_policy" "read_ssm" {
  name        = "${var.env_long}-read-ssm"
  description = "${var.env_long} AWS Systems Manager Parameter Store"
  path        = "/"
  policy      = data.aws_iam_policy_document.read_ssm.json
}


resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs-read-ssm-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.read_ssm.arn
}

