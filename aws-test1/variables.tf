## VPC tf

variable "vpcM_subnet_cidr_public" {
  description = "Public Subnet CIDR values"
  type        = list(string)
  default     = ["192.168.0.0/24", "192.168.1.0/24", "192.168.2.0/24"]
}

variable "vpcM_subnet_cidr_private" {
  description = "Private Subnet CIDR values"
  type        = list(string)
  default     = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]
}

variable "vpcM_azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

