data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "database_secret" {
  statement {
    sid       = "ReadGhostDatabaseSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.database_secret_arn]
  }
}

resource "aws_iam_role" "execution" {
  name_prefix        = "ghost-execution-"
  description        = "Allows ECS to pull Ghost and inject its database secret"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = {
    Name = "${var.name_prefix}-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "database_secret" {
  name_prefix = "ghost-database-secret-"
  role        = aws_iam_role.execution.id
  policy      = data.aws_iam_policy_document.database_secret.json
}

# Ghost receives only the media-bucket permissions declared in media.tf.
resource "aws_iam_role" "task" {
  name_prefix        = "ghost-task-"
  description        = "Application role for the Ghost container"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = {
    Name = "${var.name_prefix}-task-role"
  }
}

resource "aws_cloudwatch_log_group" "ghost" {
  name              = "/ecs/${var.name_prefix}/ghost"
  retention_in_days = 14

  tags = {
    Name = "${var.name_prefix}-ghost-logs"
  }
}

resource "aws_ecs_cluster" "ghost" {
  name = "${var.name_prefix}-cluster"

  tags = {
    Name = "${var.name_prefix}-cluster"
  }
}

resource "aws_ecs_task_definition" "ghost" {
  family                   = "${var.name_prefix}-ghost"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "ghost"
      image     = var.ghost_image
      essential = true

      portMappings = [
        {
          name          = "ghost-http"
          containerPort = var.ghost_port
          hostPort      = var.ghost_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "url"
          value = var.ghost_url
        },
        {
          name  = "database__client"
          value = "mysql"
        },
        {
          name  = "database__connection__ssl"
          value = "Amazon RDS"
        },
        {
          name  = "logging__transports"
          value = "[\"stdout\"]"
        },
        {
          name  = "storage__active"
          value = "S3Storage"
        },
        {
          name  = "storage__media__adapter"
          value = "S3Storage"
        },
        {
          name  = "storage__media__staticFileURLPrefix"
          value = "content/media"
        },
        {
          name  = "storage__files__adapter"
          value = "S3Storage"
        },
        {
          name  = "storage__files__staticFileURLPrefix"
          value = "content/files"
        },
        {
          name  = "storage__S3Storage__bucket"
          value = var.media_bucket_name
        },
        {
          name  = "storage__S3Storage__region"
          value = var.aws_region
        },
        {
          name  = "storage__S3Storage__cdnUrl"
          value = var.media_cdn_url
        },
        {
          name  = "storage__S3Storage__staticFileURLPrefix"
          value = "content/images"
        },
        {
          name  = "storage__S3Storage__multipartUploadThresholdBytes"
          value = "20971520"
        },
        {
          name  = "storage__S3Storage__multipartChunkSizeBytes"
          value = "8388608"
        },
        {
          name  = "urls__media"
          value = var.media_cdn_url
        },
        {
          name  = "urls__files"
          value = var.media_cdn_url
        }
      ]

      secrets = [
        {
          name      = "database__connection__host"
          valueFrom = "${var.database_secret_arn}:host::"
        },
        {
          name      = "database__connection__port"
          valueFrom = "${var.database_secret_arn}:port::"
        },
        {
          name      = "database__connection__database"
          valueFrom = "${var.database_secret_arn}:database::"
        },
        {
          name      = "database__connection__user"
          valueFrom = "${var.database_secret_arn}:username::"
        },
        {
          name      = "database__connection__password"
          valueFrom = "${var.database_secret_arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ghost.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ghost"
        }
      }
    }
  ])

  depends_on = [
    aws_iam_role_policy_attachment.execution,
    aws_iam_role_policy.database_secret,
    aws_iam_role_policy.media,
  ]

  tags = {
    Name = "${var.name_prefix}-ghost-task"
  }
}

resource "aws_ecs_service" "ghost" {
  name             = "${var.name_prefix}-ghost"
  cluster          = aws_ecs_cluster.ghost.id
  task_definition  = aws_ecs_task_definition.ghost.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  health_check_grace_period_seconds = 180

  # One task avoids concurrent writes to the remaining container-local filesystem.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.application_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "ghost"
    container_port   = var.ghost_port
  }

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  tags = {
    Name = "${var.name_prefix}-ghost-service"
  }
}
