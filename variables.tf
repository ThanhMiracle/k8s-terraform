############################################
# variables.tf — Biến dùng chung
############################################

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "prefix" {
  description = "Name prefix cho tất cả resource"
  type        = string
  default     = "k8s"
}

variable "location" {
  description = "Azure region (e.g. East Asia, Southeast Asia, East US)"
  type        = string
  default     = "East Asia"
}

variable "admin_username" {
  description = "Linux admin username"
  type        = string
  default     = "thanh"
}

variable "ssh_public_key" {
  description = "SSH public key (ví dụ từ ~/.ssh/id_rsa.pub)"
  type        = string
}

variable "vm_size" {
  description = "Cỡ máy ảo"
  type        = string
  default     = "Standard_D2s_v3"
}

# Danh sách tên VM cố định: 1 master + 2 worker
variable "vm_names" {
  description = "Danh sách tên VM sẽ tạo"
  type        = list(string)
  default     = ["master", "worker1", "worker2"]
}
############################################