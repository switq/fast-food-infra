variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "tf_state_bucket" {
  type = string
}

variable "tf_state_key" {
  type    = string
  default = "infra/terraform.tfstate"
}

variable "tf_state_lock_table" {
  type = string
}

variable "cognito_user_pool_name" {
  type    = string
  default = "fast-food-auth-user-pool"
}

variable "cognito_client_name" {
  type    = string
  default = "fast-food-auth-client"
}

variable "cognito_lambda_config" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "jwt_secret_name" {
  type    = string
  default = "fast-food-jwt-secret"
}

variable "jwt_secret_string" {
  type    = string
  default = "" // should be overridden in tfvars or CI
}

variable "lambda_role_name" {
  type    = string
  default = "fast-food-auth-lambda-role"
}

variable "lambda_function_name" {
  type    = string
  default = "fast-food-auth-identify"
}

variable "lambda_package_path" {
  type    = string
  default = "../fast-food-auth-lambda/deploy/fast-food-auth-lambda.zip"
}

variable "lambda_handler" {
  type    = string
  default = "dist/handlers/identifyHandler.identifyHandler"
}

variable "lambda_runtime" {
  type    = string
  default = "nodejs18.x"
}

variable "lambda_timeout" {
  type    = number
  default = 15
}

variable "api_name" {
  type    = string
  default = "fast-food-auth-api"
}

variable "api_stage_name" {
  type    = string
  default = "$default"
}

# EKS Variables
variable "eks_cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
  default     = "fast-food-cluster"
}

variable "eks_kubernetes_version" {
  description = "Versão do Kubernetes"
  type        = string
  default     = "1.27"
}

variable "eks_node_instance_types" {
  description = "Tipos de instância para os nodes EKS"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_desired_capacity" {
  description = "Capacidade desejada do node group"
  type        = number
  default     = 2
}

variable "eks_max_capacity" {
  description = "Capacidade máxima do node group"
  type        = number
  default     = 4
}

variable "eks_min_capacity" {
  description = "Capacidade mínima do node group"
  type        = number
  default     = 1
}
