
variable "EnvironmentName" {
  type    = string
  default = "UdacityProject"
}

variable "AMItoUse" {
  description = "AMI of EC2 instance"
  type        = string
}

variable "InstanceTypeToUse" {
  type    = string
  default = "t2.micro"
}