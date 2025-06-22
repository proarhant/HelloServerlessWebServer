resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  tags = var.tags
}

resource "aws_ecs_task_definition" "this" {
  family = var.task_definition_family
  container_definitions = jsonencode([
    {
      name        = var.container_name
      image       = var.container_image
      entryPoint  = var.container_entry_point
      essential   = true
      networkMode = "awsvpc"
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      # Container health check endpoint is localhost:8080/hello
      healthCheck = {
        command     = ["CMD-SHELL", format("wget -q -O - http://localhost:%s%s || exit 1", var.container_port, var.health_check_path)]
        interval    = 30
        timeout     = 5
        startPeriod = 10
        retries     = 3
      }
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name                = var.service_name
  cluster             = aws_ecs_cluster.this.id
  task_definition     = aws_ecs_task_definition.this.arn
  desired_count       = var.desired_count
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    security_groups  = var.security_groups
    subnets          = var.subnets
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  tags = var.tags
}