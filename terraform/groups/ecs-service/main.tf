terraform {
  backend "s3" {
  }
  required_version = "~> 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
#     version = "~> 4.54.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"  # Specify an appropriate version constraint
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Create ECS task role
resource "aws_iam_role" "ecs_task_role" {
  name = "${local.service_name}-${var.environment}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

module "secrets" {
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/secrets?ref=1.0.296"

  name_prefix = "${local.service_name}-${var.environment}"
  environment = var.environment
  kms_key_id  = data.aws_kms_key.kms_key.id
  secrets     = nonsensitive(local.stack_secrets)
}

module "ecs-service" {
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/ecs-service?ref=1.0.296"

  # Environmental configuration
  environment             = var.environment
  aws_region              = var.aws_region
  aws_profile             = var.aws_profile
  vpc_id                  = data.aws_vpc.vpc.id
  ecs_cluster_id          = data.aws_ecs_cluster.ecs_cluster.id
  task_execution_role_arn = data.aws_iam_role.ecs_cluster_iam_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn
  
  # Specify the correct platform architecture
  operating_system_family = "LINUX"
  cpu_architecture        = "X86_64"  # Use "ARM64" if running on Graviton instances

  # Load balancer configuration
  lb_listener_arn           = data.aws_lb_listener.rand_lb_listener.arn
  lb_listener_rule_priority = local.lb_listener_rule_priority
  lb_listener_paths         = local.lb_listener_paths

  # ECS Task container health check
  use_task_container_healthcheck    = true
  healthcheck_path                  = local.healthcheck_path
  healthcheck_matcher               = local.healthcheck_matcher
  health_check_grace_period_seconds = 300
  healthcheck_healthy_threshold     = "2"

  # Docker container details
  docker_registry   = var.docker_registry
  docker_repo       = local.docker_repo
  container_version = var.ollama_service_version
  container_port    = local.container_port

  # Service configuration
  service_name = local.service_name
  name_prefix  = local.name_prefix

  # Service performance and scaling configs
  desired_task_count                 = var.desired_task_count
  max_task_count                     = var.max_task_count
  required_cpus                      = var.required_cpus
  required_memory                    = var.required_memory
  service_autoscale_enabled          = var.service_autoscale_enabled
  service_autoscale_target_value_cpu = var.service_autoscale_target_value_cpu
  service_scaledown_schedule         = var.service_scaledown_schedule
  service_scaleup_schedule           = var.service_scaleup_schedule
  use_capacity_provider              = var.use_capacity_provider
  use_fargate                        = var.use_fargate
  fargate_subnets                    = local.application_subnet_ids

  # Cloudwatch
  cloudwatch_alarms_enabled = var.cloudwatch_alarms_enabled

  # Service environment variable and secret configs
  task_environment          = local.task_environment
  task_secrets              = local.task_secrets
  app_environment_filename  = local.app_environment_filename
  use_set_environment_files = local.use_set_environment_files

  depends_on = [module.secrets]
}

# ECS Service Security Group
resource "aws_security_group" "ecs_sg" {
  name        = "${local.service_name}-${var.environment}-ecs-sg"
  description = "Security group for ECS service"
  vpc_id      = data.aws_vpc.vpc.id
}