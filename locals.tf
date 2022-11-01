locals {
  common_tags = {
    managed-by  = "terraform"
    name = "${var.name}-${var.environment}"
    project = var.name
    environment = var.environment
    owner       = var.owner
  }
}