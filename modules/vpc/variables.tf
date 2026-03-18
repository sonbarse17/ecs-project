variable "name" {
  type        = string
  description = "Name prefix for all resources"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones"
}

variable "enable_public_subnet" {
  type        = bool
  default     = true
  description = "Enable public subnets"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR blocks for public subnets"
}

variable "enable_app_subnet" {
  type        = bool
  default     = true
  description = "Enable app subnets"
}

variable "app_subnet_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR blocks for app subnets"
}

variable "enable_data_subnet" {
  type        = bool
  default     = false
  description = "Enable data subnets"
}

variable "data_subnet_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR blocks for data subnets"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
