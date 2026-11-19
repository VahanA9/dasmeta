
variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.37"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "admin_cidr" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
