# ALB SGs restrict access to our application that accepts requests from the Internet via ALB to ECS Fargate' private network

# Security Group for ALB
resource "aws_security_group" "lb" {
  name                   = "lb-sg"
  description            = "Security group for ALB"
  vpc_id                 = aws_vpc.main.id
  revoke_rules_on_delete = true
}

# Inboud: ALB Security Group Rules to accept incoming connections from the Internet
resource "aws_security_group_rule" "alb_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  description       = "Allow HTTP inboud requests coming from internet"
  security_group_id = aws_security_group.lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# TO-DO: HTTPS inbound to be allowed if required by the app.
resource "aws_security_group_rule" "alb_https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  description       = "Allow HTTPS inboud requests coming from internet"
  security_group_id = aws_security_group.lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Outboud: ALB Security Group Rules to allow outgoing connections to the Internet
resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  description       = "Allow outboud traffic from ALB to internet"
  security_group_id = aws_security_group.lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Security Group for ECS application
# Inbound traffic to the ECS cluster is allowed only from the ALB
resource "aws_security_group" "ecs_tasks" {
  name                   = "ecs-tasks-sg"
  description            = "Allow inbound access traffic only from the ALB"
  vpc_id                 = aws_vpc.main.id
  revoke_rules_on_delete = true
}

# Inboud: ECS Security Group Rule to accept incoming connections from the ALB
resource "aws_security_group_rule" "ecs_alb_ingress" {
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  description              = "Allow incoming traffic from ALB"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = aws_security_group.lb.id
}

# Outbound: ECS app Security Group Rules to allow outgoing connections to the Internet
resource "aws_security_group_rule" "ecs_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  description       = "Allow outbound traffic from ECS"
  security_group_id = aws_security_group.ecs_tasks.id
  cidr_blocks       = ["0.0.0.0/0"]
}