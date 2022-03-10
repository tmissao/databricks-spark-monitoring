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
  subscription_id = "33d7eadb-fb41-4ef5-9c37-0d67c95a1e70"
}

provider "databricks" {
  host = azurerm_databricks_workspace.this.workspace_url
}