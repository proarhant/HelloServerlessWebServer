# ECR resources: ECR repo, ECR policy, resources to build and push image
# The Dockerfile is located at ./app directory

resource "aws_ecr_repository" "ecr" {
  name         = "ecs-fargate-repo"
  force_delete = true
}

# The ECR policy describes the management of images in the repo
locals {
  ecr_policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Expire images older than 2 days",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "sinceImagePushed",
          "countUnit" : "days",
          "countNumber" : 2
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })
}

# The ECR policy for the repo
resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  repository = aws_ecr_repository.ecr.name
  policy     = local.ecr_policy
}

#The commands below are used to build and push a docker image of the application in the app folder
locals {
  docker_login_command = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  docker_build_command = "docker build -t ${aws_ecr_repository.ecr.name} ./app"
  docker_tag_command   = "docker tag ${aws_ecr_repository.ecr.name}:latest ${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.ecr.name}:latest"
  docker_push_command  = "docker push ${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.ecr.name}:latest"
}

#This resource is for authenticating to the ECR
resource "null_resource" "docker_login" {
  provisioner "local-exec" {
    command = local.docker_login_command
  }
  triggers = {
    "run_at" = timestamp()
  }
  depends_on = [aws_ecr_repository.ecr]
}

# Building the docker image from the Dockerfile
resource "null_resource" "docker_build" {
  provisioner "local-exec" {
    command = local.docker_build_command
  }
  triggers = {
    "run_at" = timestamp()
  }
  depends_on = [null_resource.docker_login]
}

# Tag the docker image 
resource "null_resource" "docker_tag" {
  provisioner "local-exec" {
    command = local.docker_tag_command
  }
  triggers = {
    "run_at" = timestamp()
  }
  depends_on = [null_resource.docker_build]
}

# Push the docker image to our ECR repo
resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = local.docker_push_command
  }
  triggers = {
    "run_at" = timestamp()
  }
  depends_on = [null_resource.docker_tag]
}
