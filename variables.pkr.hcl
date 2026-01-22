variable "client_id" {
  type = string
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "image_version" {
  type    = string
  default = "1.0.0"
}
