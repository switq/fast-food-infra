variable "api_name" {
  type    = string
  default = "fast-food-auth-api"
}

variable "lambda_arn" {
  type = string
}

variable "stage_name" {
  type    = string
  default = "$default"
}

variable "tags" {
  type    = map(string)
  default = {}
}
