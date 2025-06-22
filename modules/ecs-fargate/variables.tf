variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "task_definition_family" {
  description = "Family name for the task definition"
  type        = string
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
}

variable "container_entry_point" {
  description = "Entry point for the container"
  type        = list(string)
  default     = []
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
}

variable "task_cpu" {
  description = "CPU units for the task (1 vCPU = 1024 units)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for the task in MiB"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Desired number of tasks to run"
  type        = number
  default     = 2
}

variable "security_groups" {
  description = "Security groups for the ECS tasks"
  type        = list(string)
}

variable "subnets" {
  description = "Subnets for the ECS tasks"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the task"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ARN of the target group for load balancing"
  type        = string
  default     = ""
}

variable "enable_autoscaling" {
  description = "Enable autoscaling for the ECS service"
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 5
}

variable "scale_up_cooldown" {
  description = "Cooldown period for scaling up (seconds)"
  type        = number
  default     = 60
}

variable "scale_down_cooldown" {
  description = "Cooldown period for scaling down (seconds)"
  type        = number
  default     = 600
}

variable "cpu_high_threshold" {
  description = "CPU utilization threshold for scaling up"
  type        = number
  default     = 75
}

variable "cpu_low_threshold" {
  description = "CPU utilization threshold for scaling down"
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "Retention period for CloudWatch logs (days)"
  type        = number
  default     = 3
}

variable "ecs_task_execution_role_name" {
  description = "Name for the ECS task execution role"
  type        = string
  default     = "EcsTaskExecutionRole"
}

variable "ecs_task_role_name" {
  description = "Name for the ECS task role"
  type        = string
  default     = "EcsTaskRole"
}

variable "ecs_auto_scale_role_name" {
  description = "Name for the ECS auto scaling role"
  type        = string
  default     = "EcsAutoScaleRole"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "health_check_path" {
  description = "Path for container health check"
  type        = string
  default     = "/hello"
}