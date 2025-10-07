terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }  # Temporarily using local backend to avoid lock issues
  # backend "s3" {
  #   bucket = "fiap-fastfood-terraform-state-dev"
  #   key    = "infra/dev/terraform.tfstate"
  #   region = "us-east-1"
  #   dynamodb_table = "fiap-terraform-lock-dev"
  #   encrypt = true
  # }
}

provider "aws" {
  region = var.aws_region
}

# Data sources para VPC padrão
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

// Use a subset of subnets for EKS control plane to avoid AZs unsupported for managed control plane
locals {
  # Explicit safe subnet ids (selected to avoid us-east-1e which is unsupported for control plane)
  eks_control_plane_subnet_ids = [
    "subnet-0f5b36cb4fb8d18e7", # us-east-1a
    "subnet-00db9020f55e66f1e", # us-east-1b
    "subnet-02e1067f075f0cd76", # us-east-1d
  ]
}

module "cognito" {
  source = "./modules/cognito"

  user_pool_name = var.cognito_user_pool_name
  client_name    = var.cognito_client_name
  lambda_config  = var.cognito_lambda_config
  tags           = var.tags
}

module "secrets" {
  source        = "./modules/secrets"
  secret_name   = var.jwt_secret_name
  description   = "JWT secret for local/dev (store real secrets in Secrets Manager for production)"
  secret_string = var.jwt_secret_string
  tags          = var.tags
}

module "iam" {
  source       = "./modules/iam"
  role_name    = var.lambda_role_name
  secrets_arns = [module.secrets.secret_arn]
  cognito_arns = [module.cognito.user_pool_arn]
  tags         = var.tags
}

module "lambda" {
  source       = "./modules/lambda"
  function_name = var.lambda_function_name
  package_path  = var.lambda_package_path
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role_arn      = module.iam.lambda_role_arn
  environment   = {
    COGNITO_USER_POOL_ID = module.cognito.user_pool_id
    COGNITO_CLIENT_ID    = module.cognito.client_id
    JWT_SECRET_ARN       = module.secrets.secret_arn
  }
  timeout = var.lambda_timeout
  tags    = var.tags
}

module "api_gateway" {
  source     = "./modules/api_gateway"
  api_name   = var.api_name
  lambda_arn = module.lambda.function_arn
  stage_name = var.api_stage_name
  tags       = var.tags
}
// Re-enable the EKS module: previously disabled due to version negotiation issues.
// Adjust `eks_kubernetes_version` in variables.tf or dev.tfvars if needed.
module "eks" {
  source = "./modules/eks"

  cluster_name         = var.eks_cluster_name
  kubernetes_version   = var.eks_kubernetes_version
  subnet_ids           = local.eks_control_plane_subnet_ids
  private_subnet_ids   = local.eks_control_plane_subnet_ids
  node_instance_types  = var.eks_node_instance_types
  desired_capacity     = var.eks_desired_capacity
  max_capacity         = var.eks_max_capacity
  min_capacity         = var.eks_min_capacity
  tags                 = var.tags
}
