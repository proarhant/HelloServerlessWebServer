
# The following vars need to be populated for the application to be deployed on Fargate ECS cluster

service_name = "devops-ecs-service"
aws_region   = "ap-southeast-2"
vpc_cidr     = "172.17.0.0/16" # The CIDR for the infrastructure
app_port     = 8080            # Port exposed by the app container to accept traffic to

# AWS Authentication
shared_config_files      = "~/.aws/config"      # Path of config file in .aws dir
shared_credentials_files = "~/.aws/credentials" # Path of credentials file in .aws dir

# Fargate configuration
fargate_cpu    = "256" # 0.25 vCPU
fargate_memory = "512" # 512MB RAM

# ECS configuration
app_count = 2 # Number of tasks (containers) to run

# Default tags for resources
default_tags = {
  Application = "DevOps App"
  Environment = "Test"
  Terraform   = "true"
}