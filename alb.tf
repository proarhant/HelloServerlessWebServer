# The ALB forwards all inbound requests to the ECS cluster
# The ALB is attached with WAF.
# The ALB together with WAF are deployed with this terraform file.

resource "aws_alb" "main" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public.*.id
  security_groups    = [aws_security_group.lb.id]
}

resource "aws_alb_target_group" "app" {
  name        = "ecs-target-group"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_endpoint # default is set to"/hello"
    unhealthy_threshold = "2"
  }
}

# Redirect all traffic (curretnly HTTP on port 80) from the ALB to the target group
# Implement path-based routing with the ALB, where only requests to the /hello route are 
# forwarded to the ECS Fargate target group

# Create a default redirect action for the listener
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = 80
  protocol          = "HTTP"

  # Default action returns a 404 for any path not explicitly routed to /hello
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "The endpoint you are attempting to access is either unavailable or does not exist.\n\nPlease verify the URL and try again, or contact your account manager if you believe this is an error."
      status_code  = "404"
    }
  }
}

# Create a listener rule to route /hello requests to the Fargagte ECS target group
resource "aws_alb_listener_rule" "hello_route" {
  listener_arn = aws_alb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.app.id
  }

  condition {
    path_pattern {
      values = ["/hello"]
    }
  }
}

### WAF attached to the ALB: The below section configures is AWS WAF Web ACL with the following configurations:
# Rate-limiting rule (e.g., 100 requests per 5 minutes from the same IP)
# Geo-blocking rule to block specific countries (e.g., China and Russia)

resource "aws_wafv2_web_acl" "alb_web_acl" {
  name        = "my-alb-waf"
  description = "Web ACL for ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "alb-waf-metrics"
    sampled_requests_enabled   = true
  }

  # Rate-Limiting Rule (120 requests per 5 minutes from the same IP)
  rule {
    name     = "rate-limit-ip"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 120  # Max 120 requests per 5 minutes from the same IP
        aggregate_key_type = "IP" # Key by the client's IP address
      }
    }

    # Added required visibility_config for each rule
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit-ip"
      sampled_requests_enabled   = true
    }
  }

  # Geo-Blocking Rule (Block traffic from specific countries)
  rule {
    name     = "geo-block"
    priority = 2

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = ["CC", "EE"] # Please use appropriate country codes
      }
    }

    # Added required visibility_config for each rule
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "geo-block"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "alb_waf_association" {
  resource_arn = aws_alb.main.id
  web_acl_arn  = aws_wafv2_web_acl.alb_web_acl.arn
}
