terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.98.0"
    }
    databricks = {
      source  = "databrickslabs/databricks"
      version = "0.5.2"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "databricks" {
  host = azurerm_databricks_workspace.this.workspace_url
}