# outputs.tf

output "alb_dnsname" {
  value = aws_alb.main.dns_name
}

output "ecs_cluster_name" {
  value = module.ecs_fargate.cluster_name
}