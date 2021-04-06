resource "aws_elasticache_replication_group" "celery_broker" {
  replication_group_id          = "${var.stack_name}-celery-broker"
  replication_group_description = "Replicated redis cluster for celery (asynchronous tasks for script-runner)"

  engine               = "redis"
  engine_version       = "6.0.5"
  parameter_group_name = "default.redis6.x"
  node_type            = "cache.t3.medium"

  automatic_failover_enabled = true
  number_cache_clusters      = 2
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.celery_broker.name
  security_group_ids         = [aws_security_group.celery_broker_firewall.id]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_elasticache_subnet_group" "celery_broker" {
  name       = "${var.stack_name}-celery-broker-subnet-group"
  subnet_ids = var.vpc_database_subnet_ids
}

resource "aws_security_group" "celery_broker_firewall" {
  name        = "${var.stack_name}-celery-broker-firewall"
  description = "Security Group for celery-broker (Redis)"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow connections from script-runner server/worker containers"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.script_worker_firewall.id, aws_security_group.script_runner_firewall.id]
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
