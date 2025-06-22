resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = "${var.cluster_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.this.name
}