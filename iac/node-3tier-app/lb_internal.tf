locals {
  internal_api_port = 80
}

resource "aws_lb" "api_internal" {
  count              = 1
  name               = "${var.env_long}-api-internal-lb"
  internal           = true
  load_balancer_type = "application"
  subnets            = module.vpc.0.private_subnets
  security_groups    = [aws_security_group.internal_api_lb.0.id]
  tags               = local.tags
}

resource "aws_lb_target_group" "api_internal" {
  count       = 1
  name        = "${var.env_long}-api-internal-lb"
  port        = local.target_services.api.host_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.0.vpc_id
  target_type = "ip"
  tags        = local.tags


  health_check {
    path = local.target_services.api.health_check_path
  }
  depends_on = [aws_lb.api_internal]
}

resource "aws_lb_listener" "api_internal" {
  count             = 1
  load_balancer_arn = aws_lb.api_internal.0.id
  port              = local.internal_api_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.api_internal.0.id
    type             = "forward"
  }

  tags = local.tags

}

resource "aws_security_group" "internal_api_lb" {
  count       = 1
  name        = "${var.env_short}-load-balancer-internal-${var.shared_region}"
  description = "controls access to the internal ALB"
  vpc_id      = module.vpc.0.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = local.internal_api_port
    to_port     = local.internal_api_port
    cidr_blocks = [module.vpc.0.vpc_cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags

}

