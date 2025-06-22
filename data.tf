data "aws_caller_identity" "current" {}

# Get available AZs in the current region
data "aws_availability_zones" "available" {
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# Moved to module/ecs-fargate
#data "aws_iam_policy_document" "assume_role_policy" {
#  statement {
#    actions = ["sts:AssumeRole"]
#
#    principals {
#      type        = "Service"
#      identifiers = ["ecs-tasks.amazonaws.com"]
#    }
#  }
#}

#data "aws_iam_policy_document" "ecs_auto_scale_role" {
#  version = "2012-10-17"
#  statement {
#    effect  = "Allow"
#    actions = ["sts:AssumeRole"]
#
#    principals {
#      type        = "Service"
#      identifiers = ["application-autoscaling.amazonaws.com"]
#    }
#  }
#}

#assume_role_policy = <<EOF
#{
# "Version": "2012-10-17",
# "Statement": [
#   {
#     "Action": "sts:AssumeRole",
#     "Principal": {
#       "Service": "ecs-tasks.amazonaws.com"
#     },
#     "Effect": "Allow",
#     "Sid": ""
#   }
# ]
#}
#EOF

#data "template_file" "devops_app" {
#  template = file("./templates/ecs/devops_app.json.tpl")
#  vars = {
#    app_image      = "${aws_ecr_repository.ecr.repository_url}:latest"
#    app_port       = var.app_port
#    fargate_cpu    = var.fargate_cpu
#    fargate_memory = var.fargate_memory
#    aws_region     = var.aws_region
#  }
#}