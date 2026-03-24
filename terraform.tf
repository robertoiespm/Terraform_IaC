# -----------------------------------------------------------------------
# Establecemos la versión de Terraform a usar y el proveedor cloud 
# -----------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}
