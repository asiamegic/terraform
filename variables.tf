variable "resource_group_name" {
  default = "myTFResourceGroup4"
}

variable "location" {
  type        = string
  default = "eastus"
  description = "location"
}

variable "webAppPrefix" {
  type        = string
  default = "bootcamp"

}


variable "vnet" {
  type        = string
  default = "10.0.0.0/16"

}

variable "username" {
  type        = string
  default    = 

}
variable "password" {
  type        = string
  default    = 

}

variable "postgresusername" {
  type        = string
  default    = 

}
variable "postgrespassword" {
  type        = string
  default    = 

}



