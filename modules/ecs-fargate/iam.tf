data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_auto_scale_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_task_execution_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name               = var.ecs_task_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = var.tags
}

# AWS now by default uses a service-linked role called AWSServiceRoleForApplicationAutoScaling_ECSService for ECS services
# ECS auto scale role
resource "aws_iam_role" "ecs_auto_scale_role" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = var.ecs_auto_scale_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_auto_scale_role.json

  tags = var.tags
}

# ECS auto scale role policy attachment
# AmazonEC2ContainerServiceAutoscaleRole is an AWS managed policy specifically designed for the Application Auto Scaling service 
# to automatically adjust the number of tasks in Amazon ECS service.
resource "aws_iam_role_policy_attachment" "ecs_auto_scale_role" {
  count      = var.enable_autoscaling ? 1 : 0
  role       = aws_iam_role.ecs_auto_scale_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}