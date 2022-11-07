################################################################################
# ECS Module
################################################################################
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.name}-${var.environment}"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.name}-1-${var.environment}"
  execution_role_arn       = var.role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory

  container_definitions = jsonencode([
    {
      name   = var.name
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
          awslogs-group         = "/ecs/${var.name}-${var.environment}"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_service_discovery_service" "main" {
  name = "${var.name}-${var.environment}"
  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 60
      type = A
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 5
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

  network_configuration {
    subnets         = var.subnetids
    security_groups = var.security_group
  }

  service_registries {
    registry_arn = aws_service_discovery_service.test-service.arn
  }

  tags = local.common_tags
}