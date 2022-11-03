variable "role_arn" {
  type    = string
  default = ""

}
variable "environment" {
  type    = string
  default = ""
}

variable "name" {
  type    = string
  default = ""
}

variable "owner" {
  type    = string
  default = ""
}

variable "cluster" {
  type    = string
  default = ""
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "iam_role" {
  type    = string
  default = ""
}
variable "desired_count" {
  type    = number
  default = null
}

variable "deployment_min_healthy_percent" {
  type    = number
  default = null
}

variable "deployment_max_percent" {
  type    = number
  default = null
}

variable "min_count" {
  type    = number
  default = null
}

variable "max_count" {
  type    = number
  default = null
}

variable "alb_listener" {
  type    = string
  default = ""
}

variable "alb_url" {
  type    = string
  default = ""
}

variable "fargate_cpu" {
  type    = number
  default = null
}

variable "fargate_memory" {
  type    = number
  default = null
}

variable "container_image" {
  type    = string
  default = ""
}

variable "app_port" {
  type    = number
  default = null
}

variable "security_group" {
  type    = string
  default = ""
}

variable "subnetids" {
  type    = list
  default = []
}
