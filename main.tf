################################################################################
# ECS Module
################################################################################
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.name}-${var.environment}"
  retention_in_days = 7
  tags = local.common_tags
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.name}-${var.environment}"
  execution_role_arn       = var.role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory

  container_definitions = jsonencode([
    {
      name   = "${var.name}-${var.environment}"
      image  = var.container_image
      cpu    = var.fargate_cpu
      memory = var.fargate_memory
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group     = "/ecs/${var.name}-${var.environment}"
          awslogs-region    = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_lb_target_group" "main" {
  name = "tg-${var.environment}${var.name}"
  target_type = "ip"
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
  tags = local.common_tags
}

resource "aws_ecs_service" "service" {
  name                               = "ms-teste"
  cluster                            = var.cluster
  task_definition                    = aws_ecs_task_definition.main.id
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_min_healthy_percent
  deployment_maximum_percent         = var.deployment_max_percent
  iam_role                           = var.iam_role
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  
  network_configuration {
    subnets         = var.subnetids
    security_groups = var.security_group
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.main.id
    container_name   = var.name
    container_port   = 80
  }
  tags = local.common_tags
}

resource "aws_appautoscaling_target" "main" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster}/${var.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = var.iam_role
  min_capacity       = var.min_count
  max_capacity       = var.max_count

  depends_on = [
    aws_ecs_service.service
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
      values = ["${var.alb_url}"]
    }
  }
}
