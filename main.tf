# The ECS Fargate gets deployed in private subnets

module "ecs_fargate" {
  source = "./modules/ecs-fargate"

  # Required variables from terraform.tfvars
  aws_region             = var.aws_region
  cluster_name           = "project-ecs-cluster"
  service_name           = "devops-ecs-service"
  task_definition_family = "devops-app-family"
  container_name         = "devops-app"
  container_image        = "${aws_ecr_repository.ecr.repository_url}:latest"
  container_port         = var.app_port

  # Resource allocation from terraform.tfvars
  task_cpu      = var.fargate_cpu
  task_memory   = var.fargate_memory
  desired_count = var.app_count

  # Networking (using existing resources)
  security_groups  = [aws_security_group.ecs_tasks.id]
  subnets          = aws_subnet.private.*.id
  assign_public_ip = false
  target_group_arn = aws_alb_target_group.app.id

  # Auto-scaling configuration
  enable_autoscaling = true
  min_capacity       = 2
  max_capacity       = 5

  # Tags from terraform.tfvars
  tags = var.default_tags
}