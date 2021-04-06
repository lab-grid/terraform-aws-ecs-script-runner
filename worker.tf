# Secrets

resource "aws_secretsmanager_secret" "basespace_cfg" {
  name   = "${var.stack_name}-basespace-cfg"
  policy = data.aws_iam_policy_document.basespace_cfg_policy.json
}

data "aws_iam_policy_document" "basespace_cfg_policy" {
  statement {
    effect = "Allow"
    principals {
      identifiers = [var.ecs_task_execution_role_arn]
      type        = "AWS"
    }
    actions = [
      "secretsmanager:GetSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret_version" "basespace_cfg" {
  secret_id     = aws_secretsmanager_secret.basespace_cfg.id
  secret_string = var.basespace_cfg

  version_stages = ["AWSCURRENT"]
}

resource "aws_iam_policy" "secrets_access" {
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:*"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "secret_access" {
  role       = var.ecs_task_execution_role_name
  policy_arn = aws_iam_policy.secrets_access.arn
}


# Service definitions

resource "aws_ecs_task_definition" "labflow_script_worker" {
  family = "labflow_script_worker"

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode       = "awsvpc"
  execution_role_arn = var.ecs_task_execution_role_arn

  cpu    = 4096
  memory = 20480

  container_definitions = <<EOF
[
  {
    "name": "labflow_script_worker",
    "essential": true,
    "image": "${var.image}:${var.image_tag}",
    "command": [ "python3 -m celery -A analysis worker --concurrency=1" ],
    "portMappings": [{
      "hostPort": 80,
      "protocol": "tcp",
      "containerPort": 80
    }],
    "mountPoints": [],
    "volumesFrom": [],
    "cpu": 4096,
    "memory": 20480,
    "environment": [
      {
        "name": "CELERY_BROKER_URL",
        "value": "redis://${aws_elasticache_replication_group.celery_broker.primary_endpoint_address}:6379"
      },
      {
        "name": "CELERY_RESULT_BACKEND",
        "value": "redis://${aws_elasticache_replication_group.celery_broker.primary_endpoint_address}:6379"
      }
    ],
    "secrets": [
      {
        "name": "BASESPACE_CFG",
        "valueFrom": "${aws_secretsmanager_secret.basespace_cfg.arn}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${var.aws_region}",
        "awslogs-group": "${var.stack_name}-logs",
        "awslogs-stream-prefix": "complete-ecs"
      }
    }
  }
]
EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_ecs_service" "labflow_script_worker" {
  name            = "labflow_script_worker"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.labflow_script_worker.arn
  # launch_type      = "FARGATE"
  platform_version = "LATEST"
  propagate_tags   = "SERVICE"

  desired_count = var.worker_count

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = var.vpc_public_subnet_ids
    security_groups  = [aws_security_group.script_worker_firewall.id]
    assign_public_ip = true
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "script_worker_firewall" {
  name        = "script_worker_firewall"
  description = "Security Group for script_worker containers"
  vpc_id      = var.vpc_id

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
