locals {
  common_tags = {
    managed-by  = "terraform"
    environment = var.environment
    owner       = var.owner
  }
}