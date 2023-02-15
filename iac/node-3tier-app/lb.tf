locals {
  app_port = 80
}

resource "aws_lb" "alb" {
  count              = 1
  name               = "${var.env_long}-public-lb"
  internal           = false # false
  load_balancer_type = "application"
  subnets            = module.vpc.0.public_subnets
  security_groups    = [aws_security_group.lb.0.id]
  tags               = local.tags
}

resource "aws_lb_target_group" "group" {
  for_each    = local.target_services
  name        = "${var.env_long}-${each.key}-lb"
  port        = each.value.host_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.0.vpc_id
  target_type = "ip"

  tags = local.tags

  health_check {
    path = each.value.health_check_path
  }
  depends_on = [aws_lb.alb]
}

resource "aws_lb_listener" "http" {
  count             = 1
  load_balancer_arn = aws_lb.alb.0.id
  port              = local.app_port
  protocol          = local.app_port == 443 ? "HTTPS" : "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.group["web"].id
    type             = "forward"
  }

  tags = local.tags

}


resource "aws_lb_listener_rule" "api" {
  count        = 1
  listener_arn = aws_lb_listener.http.0.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.group["api"].id
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
  tags = local.tags

}

resource "aws_lb_listener_rule" "grafana" {
  count        = 1
  listener_arn = aws_lb_listener.http.0.arn
  priority     = 101
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.group["grafana"].id
  }

  condition {
    path_pattern {
      values = ["/grafana", "/grafana/*"]
    }
  }

  tags = local.tags

}



resource "aws_lb_listener" "http_redirect" {
  count             = local.app_port != 80 ? 1 : 0
  load_balancer_arn = aws_lb_listener.http.0.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = local.app_port
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  tags = local.tags


}

resource "aws_security_group" "lb" {
  count       = 1
  name        = "${var.env_short}-load-balancer-security-group-${var.shared_region}"
  description = "controls access to the ALB"
  vpc_id      = module.vpc.0.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = local.app_port
    to_port     = local.app_port
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags

}

