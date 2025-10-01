variable "function_name" { type = string }
variable "package_path" { type = string }
variable "handler" { type = string }
variable "runtime" { 
  type = string 
  default = "nodejs18.x" 
}
variable "role_arn" { type = string }
variable "environment" { 
  type = map(string) 
  default = {} 
}
variable "timeout" { 
  type = number 
  default = 30 
}
variable "tags" { 
  type = map(string) 
  default = {} 
}
