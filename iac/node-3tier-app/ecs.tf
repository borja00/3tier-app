resource "aws_ecs_cluster" "cluster" {
  name = var.ecs_cluster_name
}

locals {

  target_services = {
    api = {
      host_port         = 8001
      health_check_path = "/api/status"
    },
    web = {
      host_port         = 8002
      health_check_path = "/"
    },
    grafana = {
      host_port         = 3000
      health_check_path = "/api/health"
    }
  }

  ecs_services = {
    api = {
      instance_count = var.instance_count
      target         = local.target_services.api
      target_groups  = [aws_lb_target_group.group["api"].id, aws_lb_target_group.api_internal.0.id]
      secrets = [{
        name      = "DB",
        valueFrom = aws_ssm_parameter.pg["database_name"].arn
        }, {
        name      = "DBUSER",
        valueFrom = aws_ssm_parameter.pg["username"].arn
        }, {
        name      = "DBPASS",
        valueFrom = aws_ssm_parameter.pg["password"].arn
        }, {
        name      = "DBHOST",
        valueFrom = aws_ssm_parameter.pg["address"].arn
        }, {
        name      = "DBPORT",
        valueFrom = aws_ssm_parameter.pg["port"].arn
        },
      ]
      environment = [
        { name : "PORT", value : tostring(8001) },
      ]
    },
    web = {
      instance_count = var.instance_count
      target         = local.target_services.web
      target_groups  = [aws_lb_target_group.group["web"].id]
      secrets = [
        {
          name      = "CDN_DOMAIN",
          valueFrom = aws_ssm_parameter.cdn_domain.0.arn
      }]
      environment = [
        { name : "PORT", value : tostring(8002) },
        { name : "API_HOST", value : "http://${aws_lb.api_internal.0.dns_name}" },
      ]

    },
    grafana = {
      instance_count = 1
      target         = local.target_services.grafana
      target_groups  = [aws_lb_target_group.group["grafana"].id]
      secrets = [
        {
          name      = "GF_SECURITY_ADMIN_PASSWORD",
          valueFrom = aws_ssm_parameter.grafana_admin_password.0.arn
        },
        {
          name      = "AWS_ACCESS_KEY_ID",
          valueFrom = aws_ssm_parameter.grafana_aws_access_key_id.0.arn
        },
        {
          name      = "AWS_SECRET_ACCESS_KEY",
          valueFrom = aws_ssm_parameter.grafana_aws_secret_access_key.0.arn
        }

      ]
      environment = [
        {
          name : "AWS_REGION",
          value : var.shared_region
        },
        {
          name : "GF_SERVER_DOMAIN",
          value : aws_lb.alb.0.dns_name
        },
        {
          name : "GF_SERVER_ROOT_URL",
          value : "%(protocol)s://%(domain)s:%(http_port)s/grafana/"
        },
        {
          name : "GF_SERVER_SERVE_FROM_SUB_PATH",
          value : "true"
        },
      ]
    }
  }
}




# Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  for_each    = var.create_services ? local.ecs_services : toset({})
  name        = "${var.env_short}-ecs-${each.key}-tasks-security-group-${var.shared_region}"
  description = "allow inbound access from the ALB only"
  vpc_id      = module.vpc.0.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = each.value.target.host_port
    to_port         = each.value.target.host_port
    security_groups = [aws_security_group.lb.0.id, aws_security_group.internal_api_lb.0.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags

}

resource "aws_cloudwatch_log_group" "logs" {
  for_each = var.create_services ? local.ecs_services : toset({})
  name     = each.key
  tags     = local.tags
}

resource "aws_ecs_task_definition" "app" {
  for_each                 = var.create_services && var.create_database ? local.ecs_services : {}
  family                   = "${var.env_short}-task-${each.key}-${var.shared_region}"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory

  container_definitions = jsonencode([{
    name      = each.key # This can not be change as it is referenced in github actions
    image     = "${var.aws_account_id}.dkr.ecr.${var.shared_region}.amazonaws.com/${each.key}:latest"
    essential = true
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-group" : each.key,
        "awslogs-region" : var.shared_region,
        "awslogs-stream-prefix" : var.env_short
      }
    },
    secrets     = each.value.secrets
    environment = each.value.environment
    portMappings = [{
      protocol      = "tcp"
      containerPort = each.value.target.host_port
      host_port     = each.value.target.host_port
  }] }])

  tags = local.tags


  depends_on = [aws_db_instance.default]
}

resource "aws_ecs_service" "main" {
  for_each        = var.create_services && var.create_database ? local.ecs_services : {}
  name            = "service-${each.key}"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.app[each.key].arn
  desired_count   = each.value.instance_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = tonumber(each.value.instance_count) == 1 ? 100 : 90
  # each.value.instance_count == 1 is not working
  deployment_maximum_percent = tonumber(each.value.instance_count) == 1 ? 200 : 150

  tags = local.tags


  lifecycle {
    ignore_changes = [task_definition]
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks[each.key].id]
    subnets          = module.vpc.0.private_subnets
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = toset(each.value.target_groups)
    content {
      target_group_arn = load_balancer.key
      container_name   = each.key
      container_port   = each.value.target.host_port

    }
  }

  depends_on = [aws_iam_role_policy_attachment.ecs-task-execution-role-policy-attachment, aws_lb_target_group.group]
}

