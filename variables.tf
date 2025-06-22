variable "aws_region" {
  type        = string
  description = "The AWS region where the infra is deployed to host the app"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC where the infra is deployed"
}

variable "app_port" {
  description = "Port exposed by the app container to accept traffic to"
}

variable "shared_config_files" {
  description = "Path of config file in .aws dir e.g. ~/.aws/config"
}

variable "shared_credentials_files" {
  description = "Path of credentials file in .aws dir e.g. ~/.aws/credentials"
}

variable "az_count" {
  description = "The number of AZs used for the infrastructure in the region"
  default     = "2"
}

variable "app_image" {
  description = "Container image for the app"
  default     = "nginx:latest"
}

variable "app_count" {
  description = "Number of app containers to run in the Fargate ECS cluster"
  default     = 2
}

#variable "ec2_task_execution_role_name" {
#    description = "ECS task execution role name"
#    default = "EcsTaskExecutionRole"
#}

variable "ecs_auto_scale_role_name" {
  description = "ECS auto scale role name"
  default     = "EcsAutoScaleRole"
}

variable "fargate_cpu" {
  description = "Fargate ECS CPU units (1 vCPU = 1024 CPU units) to provision"
  default     = "256"
}

variable "fargate_memory" {
  description = "Fargate ECS memory (in MiB) to provision"
  default     = "512"
}

variable "health_check_endpoint" {
  description = "Endpoint for ALB health check"
  type        = string
  default     = "/hello"
}

variable "health_check_matcher" {
  description = "HTTP status code to match for ALB health check"
  type        = string
  default     = "200"
}

variable "default_tags" {
  type = map(any)
  default = {
    Application = "Test DevOps App"
    Environment = "Test"
  }
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}