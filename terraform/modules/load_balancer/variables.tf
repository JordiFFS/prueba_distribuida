variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_port" {
  type = number
}

variable "alb_security_group_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}