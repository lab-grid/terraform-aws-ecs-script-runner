data "aws_caller_identity" "current" {}


# Service definitions

resource "aws_ecs_task_definition" "labflow_script_runner" {
  family = "labflow_script_runner"

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode       = "awsvpc"
  execution_role_arn = var.ecs_task_execution_role_arn

  cpu    = 256
  memory = 512

  container_definitions = <<EOF
[
  {
    "name": "labflow_script_runner",
    "essential": true,
    "image": "${var.image}:${var.image_tag}",
    "portMappings": [{
      "hostPort": 80,
      "protocol": "tcp",
      "containerPort": 80
    }],
    "mountPoints": [],
    "volumesFrom": [],
    "cpu": 256,
    "memory": 512,
    "environment": [
      {
        "name": "PORT",
        "value": "80"
      },
      {
        "name": "FLASK_ENV",
        "value": "production"
      },
      {
        "name": "PROPAGATE_EXCEPTIONS",
        "value": "False"
      },
      {
        "name": "AUTH_PROVIDER",
        "value": "auth0"
      },
      {
        "name": "AUTH0_DOMAIN",
        "value": "${var.auth0_domain}"
      },
      {
        "name": "AUTH0_CLIENT_ID",
        "value": "${var.auth0_client_id}"
      },
      {
        "name": "AUTH0_API_AUTHORITY",
        "value": "https://${var.auth0_domain}/"
      },
      {
        "name": "AUTH0_API_AUDIENCE",
        "value": "${var.auth0_audience}"
      },
      {
        "name": "AUTH0_AUTHORIZATION_URL",
        "value": "https://${var.auth0_domain}/authorize"
      },
      {
        "name": "AUTH0_TOKEN_URL",
        "value": "https://${var.auth0_domain}/oauth/token"
      },
      {
        "name": "CELERY_BROKER_URL",
        "value": "redis://${aws_elasticache_replication_group.celery_broker.primary_endpoint_address}:6379"
      },
      {
        "name": "CELERY_RESULT_BACKEND",
        "value": "redis://${aws_elasticache_replication_group.celery_broker.primary_endpoint_address}:6379"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${var.aws_region}",
        "awslogs-group": "${var.stack_name}-logs",
        "awslogs-stream-prefix": "complete-ecs"
      }
    },
    "healthCheck": {
      "retries": 3,
      "command": [
        "CMD-SHELL",
        "wget -O /dev/null -o /dev/null -T 5 -t 1 http://localhost/health || exit 1"
      ],
      "timeout": 6,
      "interval": 30,
      "startPeriod": null
    }
  }
]
EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_ecs_service" "labflow_script_runner" {
  name            = "labflow_script_runner"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.labflow_script_runner.arn
  # launch_type      = "FARGATE"
  platform_version = "LATEST"
  propagate_tags   = "SERVICE"

  desired_count = var.server_count

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  health_check_grace_period_seconds  = 10

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  deployment_controller {
    type = "ECS"
  }

  load_balancer {
    target_group_arn = module.script_runner_alb.target_group_arns[0]
    container_name   = "labflow_script_runner"
    container_port   = 80
  }

  network_configuration {
    subnets          = var.vpc_public_subnet_ids
    security_groups  = [aws_security_group.script_runner_firewall.id]
    assign_public_ip = true
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "script_runner_firewall" {
  name        = "script_runner_firewall"
  description = "Security Group for script_runner containers"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


# DNS/SSL

resource "aws_acm_certificate" "script_runner" {
  domain_name       = var.dns_name
  validation_method = "DNS"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_route53_record" "script_runner_validation" {
  name    = tolist(aws_acm_certificate.script_runner.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.script_runner.domain_validation_options)[0].resource_record_type
  zone_id = var.dns_zone_id
  records = [tolist(aws_acm_certificate.script_runner.domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "script_runner_cert" {
  certificate_arn         = aws_acm_certificate.script_runner.arn
  validation_record_fqdns = [aws_route53_record.script_runner_validation.fqdn]
}

resource "aws_route53_record" "script_runner_alb" {
  zone_id = var.dns_zone_id
  name    = "script-runner"
  type    = "A"

  alias {
    name                   = module.script_runner_alb.this_lb_dns_name
    zone_id                = module.script_runner_alb.this_lb_zone_id
    evaluate_target_health = true
  }
}


# Load Balancers

resource "aws_security_group" "script_runner_lb" {
  name        = "script_runner_lb"
  description = "Allow HTTP/TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "Allow LoadBalancer to communicate with ECS containers"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.script_runner_firewall.id]
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# resource "aws_s3_bucket" "script_runner_alb_logs" {
#   bucket = var.lb_log_bucket
#   acl    = "private"
# }

module "script_runner_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = length("${var.stack_name}-script-runner-alb") > 32 ? substr("${var.stack_name}-script-runner-alb", 0, 32) : "${var.stack_name}-script-runner-alb"

  load_balancer_type = "application"

  vpc_id          = var.vpc_id
  subnets         = var.vpc_public_subnet_ids
  security_groups = [aws_security_group.script_runner_lb.id]

  # TODO: Change this back once there is a proper "poll" api.
  idle_timeout = 600

  # access_logs = {
  #   bucket = var.lb_log_bucket
  # }

  target_groups = [
    {
      name_prefix      = "srvr-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = aws_acm_certificate.script_runner.arn
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
