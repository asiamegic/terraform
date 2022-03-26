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
  default    = "artemrafikov"

}
variable "password" {
  type        = string
  default    = "0542877567A!"

}



