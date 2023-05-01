variable "EnvironmentName" {
  type    = string
  default = "UdacityProject"
}

variable "VpcCidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "PublicSubnet1CIDR" {
  type    = string
  default = "10.0.0.0/24"
}

variable "PublicSubnet2CIDR" {
  type    = string
  default = "10.0.1.0/24"
}

variable "PrivateSubnet1CIDR" {
  type    = string
  default = "10.0.2.0/24"
}

variable "PrivateSubnet2CIDR" {
  type    = string
  default = "10.0.3.0/24"
}
