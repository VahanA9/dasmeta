variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "dasmeta-eks"
}

variable "admin_cidr" {
  description = "Public IP allowed to access EKS API"
  type        = string
  default     = "5.77.200.80/32"
}
