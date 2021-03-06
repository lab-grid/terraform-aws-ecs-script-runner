variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "IAM role ARN to apply to running containers. Can be used to grant script access to AWS services (such as a database). Must match 'ecs_task_execution_role_name'."
}

variable "ecs_task_execution_role_name" {
  type        = string
  description = "IAM role name to apply to running containers. Can be used to grant script access to AWS services (such as a database)."
}

variable "ecs_cluster_id" {
  type        = string
  description = "Identifier of existing ECS cluster to deploy to."
}

variable "vpc_id" {
  type        = string
  description = "Identier of existing VPC to deploy to."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR for VPC."
}

variable "vpc_public_subnet_ids" {
  type        = list(string)
  description = "VPC public subnet ids."
}

variable "vpc_database_subnet_ids" {
  type        = list(string)
  description = "VPC database subnet ids."
}

variable "dns_subdomain" {
  type        = string
  default     = "script-runner"
  description = "Subdomain to prefix to dns_zone_name. API will be served under this subdomain."
}

variable "dns_zone_id" {
  type        = string
  description = "Identifier of the Route53 Hosted Zone for the parent domain of this instance of script-runner."
}

variable "auth_provider" {
  type        = string
  description = "Auth provider to use for authentication/authorization. Supports 'auth0' and 'none'."
  default     = "auth0"
}

variable "auth0_domain" {
  type        = string
  description = "Domain for Auth0 client used to authenticate users calling script-runner's API. Required if auth_provider is set to 'auth0'."
  default     = ""
}

variable "auth0_audience" {
  type        = string
  description = "Audience for Auth0 client used to authenticate users calling script-runner's API. Required if auth_provider is set to 'auth0'."
  default     = ""
}

variable "auth0_client_id" {
  type        = string
  description = "Identifier for Auth0 client used to authenticate users calling script-runner's API. Required if auth_provider is set to 'auth0'."
  default     = ""
}

# variable "lb_log_bucket" {
#   type        = string
#   description = "S3 bucket to store Load Balancer access logs in."
# }

variable "stack_name" {
  type        = string
  default     = "script-runner"
  description = "Prefix for names of resources created by terraform."
}

variable "worker_count" {
  type        = number
  default     = 1
  description = "Number of worker container instances to run."
}

variable "server_count" {
  type        = number
  default     = 1
  description = "Number of server container instances to run."
}

variable "image" {
  type = string
}

variable "image_tag" {
  type    = string
  default = "latest"
}
