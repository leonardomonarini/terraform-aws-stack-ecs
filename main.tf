################################################################################
# ECS Module
################################################################################
resource "aws_cloudwatch_log_group" "main" {
  name = "/ecs/${var.name}-${var.environment}"
  retention_in_days = 7
  
  tags {
    tags = merge(
      local.common_tags,
      {
        Name        = "tg${var.environment}${var.name}"
        Project     = "${var.name}"
        Environment = "${var.environment}"
      }
    )
  }
}

resource "aws_ecs_task_definition" "main" {
  family = "${var.name}-${var.environment}"
  execution_role_arn = var.role_arn
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = var.fargate_cpu
  memory = var.fargate_memory

  container_definitions = jsonencode ([
    {
      name = var.name
      image = var.container_image
      cpu = var.fargate_cpu
      memory = var.fargate_memory
      port_mappings = [
        {
          container_port = var.app_port
          host_port = var.app_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/${var.name}-${var.environment}"
          awslogs-region = "us-east-1"
          aws-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_lb_target_group" "main" {
  name = "tg${var.environment}${var.name}"
  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    timeout             = "3"
    path                = "/healthz"
    unhealthy_threshold = "2"
  }
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags {
    tags = merge(
      local.common_tags,
      {
        Name        = "tg${var.environment}${var.name}"
        Project     = "${var.name}"
        Environment = "${var.environment}"
      }
    )
  }
}

resource "aws_ecs_service" "service" {
  name                               = var.name
  cluster                            = var.cluster
  task_definition                    = aws_ecs_task_definition.main.id
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_min_healthy_percent
  deployment_maximum_percent         = var.deployment_max_percent
  iam_role                           = var.iam_role

  load_balancer {
    target_group_arn = aws_lb_target_group.main.id
    container_name   = var.name
    container_port   = 80
  }
  tags {
    tags = merge(
      local.common_tags,
      {
        Name        = "tg${var.environment}${var.name}"
        Project     = "${var.name}"
        Environment = "${var.environment}"
      }
    )
  }
}

resource "aws_appautoscaling_target" "main" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster}/${var.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = var.iam_role
  min_capacity       = var.min_count
  max_capacity       = var.max_count

  depends_on = [
    "aws_ecs_service.service"
  ]
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = var.alb_listener

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = var.alb_url
    }
  }
}