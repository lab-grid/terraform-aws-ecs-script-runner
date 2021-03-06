# terraform-script-runner-aws-ecs

This module deploys the script-runner server/worker as an AWS ECS service.

## Requirements

* A valid AWS account
* A published docker container with both `script-runner` and your script of choice installed

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_script_runner_alb"></a> [script\_runner\_alb](#module\_script\_runner\_alb) | terraform-aws-modules/alb/aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.script_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.script_runner_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_ecs_service.labflow_script_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.labflow_script_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.labflow_script_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.labflow_script_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_elasticache_replication_group.celery_broker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) | resource |
| [aws_elasticache_subnet_group.celery_broker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |
| [aws_iam_policy.secrets_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.secret_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_route53_record.script_runner_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.script_runner_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_secretsmanager_secret.basespace_cfg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.basespace_cfg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.celery_broker_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.script_runner_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.script_runner_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.script_worker_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.basespace_cfg_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.dns_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auth0_audience"></a> [auth0\_audience](#input\_auth0\_audience) | Audience for Auth0 client used to authenticate users calling script-runner's API. | `string` | n/a | yes |
| <a name="input_auth0_client_id"></a> [auth0\_client\_id](#input\_auth0\_client\_id) | Identifier for Auth0 client used to authenticate users calling script-runner's API. | `string` | n/a | yes |
| <a name="input_auth0_domain"></a> [auth0\_domain](#input\_auth0\_domain) | Domain for Auth0 client used to authenticate users calling script-runner's API. | `string` | n/a | yes |
| <a name="input_auth_provider"></a> [auth\_provider](#input\_auth\_provider) | Auth provider to use for authentication/authorization. Supports 'auth0' and 'none'. | `string` | `"auth0"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | `"us-west-1"` | no |
| <a name="input_dns_subdomain"></a> [dns\_subdomain](#input\_dns\_subdomain) | Subdomain to prefix to dns\_zone\_name. API will be served under this subdomain. | `string` | `"script-runner"` | no |
| <a name="input_dns_zone_id"></a> [dns\_zone\_id](#input\_dns\_zone\_id) | Identifier of the Route53 Hosted Zone for the parent domain of this instance of script-runner. | `string` | n/a | yes |
| <a name="input_ecs_cluster_id"></a> [ecs\_cluster\_id](#input\_ecs\_cluster\_id) | Identifier of existing ECS cluster to deploy to. | `string` | n/a | yes |
| <a name="input_ecs_task_execution_role_arn"></a> [ecs\_task\_execution\_role\_arn](#input\_ecs\_task\_execution\_role\_arn) | IAM role ARN to apply to running containers. Can be used to grant script access to AWS services (such as a database). Must match 'ecs\_task\_execution\_role\_name'. | `string` | n/a | yes |
| <a name="input_ecs_task_execution_role_name"></a> [ecs\_task\_execution\_role\_name](#input\_ecs\_task\_execution\_role\_name) | IAM role name to apply to running containers. Can be used to grant script access to AWS services (such as a database). | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | n/a | `string` | n/a | yes |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | n/a | `string` | `"latest"` | no |
| <a name="input_server_count"></a> [server\_count](#input\_server\_count) | Number of server container instances to run. | `number` | `1` | no |
| <a name="input_stack_name"></a> [stack\_name](#input\_stack\_name) | Prefix for names of resources created by terraform. | `string` | `"script-runner"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR for VPC. | `string` | n/a | yes |
| <a name="input_vpc_database_subnet_ids"></a> [vpc\_database\_subnet\_ids](#input\_vpc\_database\_subnet\_ids) | VPC database subnet ids. | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Identier of existing VPC to deploy to. | `string` | n/a | yes |
| <a name="input_vpc_public_subnet_ids"></a> [vpc\_public\_subnet\_ids](#input\_vpc\_public\_subnet\_ids) | VPC public subnet ids. | `list(string)` | n/a | yes |
| <a name="input_worker_count"></a> [worker\_count](#input\_worker\_count) | Number of worker container instances to run. | `number` | `1` | no |

## Outputs

No outputs.
