variable "subscription_id" {
  type        = string
  default = "7521e65a-99b2-45f8-a337-63db2f8bcfd6"
  description = "From: az account show --query id -o tsv"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "southeastasia"
}

variable "prefix" {
  type        = string
  description = "Name prefix (lowercase letters/numbers)"
  default     = "boutique"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "node_size" {
  type        = string
  description = "Keep B2s unless quota forces Standard_B1s"
  default     = "Standard_B2ms"
}